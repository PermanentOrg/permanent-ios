//
//  BackgroundUploadSessionManager.swift
//  Permanent
//
//  Created by Lucian Cerbu on 23.04.2026.
//

import Foundation
import os.log

class BackgroundUploadSessionManager: NSObject {
    static let shared = BackgroundUploadSessionManager()
    static let backgroundSessionIdentifier = "org.permanent.PermanentArchive.backgroundUpload"

    /// Notification posted when a background upload task completes (success or failure).
    /// userInfo: ["taskIdentifier": Int, "error": Error?]
    static let uploadDidCompleteNotification = Notification.Name("BackgroundUploadSessionManager.uploadDidComplete")

    private let logger = Logger(subsystem: "com.permanent.ios", category: "BackgroundUpload")

    /// Stored by AppDelegate when iOS wakes the app for background session events.
    var backgroundSessionCompletionHandler: (() -> Void)?

    /// Dedicated serial queue for delegate callbacks.
    private let delegateQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "BackgroundUploadSessionManager.delegateQueue"
        return queue
    }()

    /// The background URLSession. Lazily created so it reconnects to in-flight tasks.
    private(set) lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: Self.backgroundSessionIdentifier)
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        config.shouldUseExtendedBackgroundIdleMode = true
        config.timeoutIntervalForResource = 86400 // 24 hours
        return URLSession(configuration: config, delegate: self, delegateQueue: delegateQueue)
    }()

    /// In-memory map of taskIdentifier → completion callback for in-process operations.
    private var completionHandlers: [Int: (Error?) -> Void] = [:]
    private let lock = NSLock()

    /// Directory in the app group container for temp upload files.
    static var uploadTempDirectory: URL {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ExtensionUploadManager.appSuiteGroup)!
        let dir = container.appendingPathComponent("BackgroundUploads", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private override init() {
        super.init()
    }

    /// Call on app launch to reconnect to any in-flight background tasks.
    func reconnectToExistingSession() {
        // Accessing `session` triggers the lazy initializer, which reconnects
        // to any tasks from a previous app session.
        session.getTasksWithCompletionHandler { [weak self] _, uploadTasks, _ in
            guard let self = self else { return }
            if !uploadTasks.isEmpty {
                self.logger.info("Reconnected to \(uploadTasks.count, privacy: .public) in-flight background upload tasks")
            }
        }
    }

    /// Start a background upload and register a completion handler.
    /// - Parameters:
    ///   - request: The URLRequest for the S3 upload.
    ///   - fileURL: Path to the temp file containing the multipart body (must be in the app group container).
    ///   - metadata: The metadata to persist so registerRecord can run after relaunch.
    ///   - completion: Called when the upload finishes. May not be called if the app is terminated
    ///                 (in that case BackgroundUploadCompletionHandler handles it on relaunch).
    /// - Returns: The task identifier for tracking.
    @discardableResult
    func startUpload(request: URLRequest, fileURL: URL, metadata: BackgroundUploadMetadata, completion: @escaping (Error?) -> Void) -> Int {
        let task = session.uploadTask(with: request, fromFile: fileURL)
        let taskId = task.taskIdentifier

        // Persist metadata with the real task identifier
        var updatedMetadata = metadata
        // Since taskIdentifier in the passed metadata is a placeholder (0),
        // we need to create a new one with the real task identifier.
        let finalMetadata = BackgroundUploadMetadata(
            fileInfoId: metadata.fileInfoId,
            fileName: metadata.fileName,
            s3Url: metadata.s3Url,
            destinationUrl: metadata.destinationUrl,
            createdDT: metadata.createdDT,
            folderId: metadata.folderId,
            folderLinkId: metadata.folderLinkId,
            tempFilePath: metadata.tempFilePath,
            taskIdentifier: taskId
        )
        BackgroundUploadMetadata.append(finalMetadata)

        lock.lock()
        completionHandlers[taskId] = completion
        lock.unlock()

        task.resume()
        logger.info("Started background upload task \(taskId, privacy: .public) for file: \(metadata.fileName, privacy: .public)")

        return taskId
    }

    /// Remove the in-memory completion handler (e.g. when an UploadOperation is cancelled).
    func removeCompletionHandler(forTaskIdentifier taskId: Int) {
        lock.lock()
        completionHandlers.removeValue(forKey: taskId)
        lock.unlock()
    }

    /// Clean up a temp file after upload completes.
    func cleanupTempFile(at path: String) {
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
        logger.debug("Cleaned up temp file: \(path, privacy: .public)")
    }
}

// MARK: - URLSessionTaskDelegate

extension BackgroundUploadSessionManager: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        let taskId = task.taskIdentifier

        // Look up metadata for this task to get file info
        if let metadata = BackgroundUploadMetadata.find(taskIdentifier: taskId) {
            DispatchQueue.main.async {
                let userInfo: [String: Any] = ["fileInfoId": metadata.fileInfoId, "progress": progress]
                NotificationCenter.default.post(name: UploadOperation.uploadProgressNotification, object: nil, userInfo: userInfo)

                let queueIndex = UploadManager.shared.uploadQueue.operations
                    .compactMap { $0 as? UploadOperation }
                    .firstIndex(where: { $0.file.id == metadata.fileInfoId })
                let fileIndex = (queueIndex ?? 0) + 1

                UploadLiveActivityManager.shared.updateProgress(
                    fileInfoId: metadata.fileInfoId,
                    fileName: metadata.fileName,
                    fileIndex: fileIndex,
                    fileProgress: progress
                )
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let taskId = task.taskIdentifier

        if let error = error {
            logger.error("Background upload task \(taskId, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
        } else if let response = task.response as? HTTPURLResponse {
            logger.info("Background upload task \(taskId, privacy: .public) completed with status: \(response.statusCode, privacy: .public)")
        }

        // Determine success
        let uploadError: Error?
        if let error = error {
            uploadError = error
        } else if let response = task.response as? HTTPURLResponse, response.statusCode >= 200, response.statusCode < 300 {
            uploadError = nil
        } else {
            uploadError = UploadError.s3
        }

        // Try in-memory completion handler first (UploadOperation is still alive)
        lock.lock()
        let handler = completionHandlers.removeValue(forKey: taskId)
        lock.unlock()

        if let handler = handler {
            handler(uploadError)
        } else {
            // App was relaunched — no in-memory handler. Use BackgroundUploadCompletionHandler.
            if uploadError == nil, let metadata = BackgroundUploadMetadata.find(taskIdentifier: taskId) {
                logger.info("No in-memory handler for task \(taskId, privacy: .public). Using BackgroundUploadCompletionHandler.")
                BackgroundUploadCompletionHandler.handleCompletedUpload(metadata: metadata)
            } else {
                // Upload failed and no handler — just clean up
                if let metadata = BackgroundUploadMetadata.find(taskIdentifier: taskId) {
                    cleanupTempFile(at: metadata.tempFilePath)
                    BackgroundUploadMetadata.remove(taskIdentifier: taskId)
                    DispatchQueue.main.async {
                        UploadLiveActivityManager.shared.fileCompleted(success: false)
                    }
                }
            }
        }

        // Post notification for any observers
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Self.uploadDidCompleteNotification,
                object: nil,
                userInfo: ["taskIdentifier": taskId, "error": uploadError as Any]
            )
        }
    }
}

// MARK: - URLSessionDelegate

extension BackgroundUploadSessionManager: URLSessionDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        logger.info("Background session finished all events")
        DispatchQueue.main.async { [weak self] in
            self?.backgroundSessionCompletionHandler?()
            self?.backgroundSessionCompletionHandler = nil
        }
    }
}
