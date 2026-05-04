//
//  UploadOperation.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 09.06.2021.
//

import Foundation
import UIKit
import os.log

// Extension-safe wrapper for UIApplication.shared access.
// UIApplication.shared is unavailable in app extensions, so we access it
// indirectly to avoid compile-time errors when this file is compiled for extensions.
private func extensionSafeApplication() -> UIApplication? {
    let selector = NSSelectorFromString("sharedApplication")
    guard UIApplication.responds(to: selector) else { return nil }
    return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
}

enum UploadError: Error {
    case presignedURL
    case s3
    case registerRecord
    case authenticationRequired
}

class UploadOperation: BaseOperation, @unchecked Sendable {
    static let uploadProgressNotification = Notification.Name("UploadOperation.uploadProgressNotification")
    static let uploadFinishedNotification = Notification.Name("UploadOperation.uploadFinishedNotification")
    static let registerRecordTimingNotification = Notification.Name("UploadOperation.registerRecordTimingNotification")
    
    private let logger = Logger(subsystem: "com.permanent.ios", category: "UploadOperation")
    private let flowLogger = Logger(subsystem: "com.permanent.ios", category: "UploadFlow")
    
    let file: FileInfo
    let handler: ((Error?) -> Void)
    
    var s3Url: String!
    var destinationUrl: String!
    var fields: [String: String]!
    var createdDT: String!
    
    var progress: Double = 0
    var error: UploadError?

    var backgroundTaskIdentifier: Int?
    private var foregroundUploadTask: URLSessionUploadTask?
    private var foregroundTempFileURL: URL?
    private var progressObservation: NSKeyValueObservation?

    private static let foregroundSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 3600
        return URLSession(configuration: config)
    }()

    var didSentFinishNotification: Bool = false
    
    lazy var prefixData: Data = {
        return getHttpBody()
    }()
    
    lazy var boundary: String = {
        var uuid = UUID().uuidString
        uuid = uuid.replacingOccurrences(of: "-", with: "")
        uuid = uuid.map { $0.lowercased() }.joined()

        let boundary = uuid + "\(Int(Date.timeIntervalSinceReferenceDate))"

        return boundary
    }()
    
    var didAppendPrefix = false
    var isEOF = false
    
    var uploadedFile: RecordVOData?
    
    var getPresignedURLOperation: APIOperation?
    var registerRecordOperation: APIOperation?
    
    var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid

    private var foregroundObserver: NSObjectProtocol?
    private var operationStartTime: Date?
    private var phaseStartTime: Date?

    private var elapsed: String {
        guard let start = operationStartTime else { return "0.0" }
        return String(format: "%.1f", Date().timeIntervalSince(start))
    }

    private var phaseDuration: String {
        guard let start = phaseStartTime else { return "0.0" }
        return String(format: "%.1f", Date().timeIntervalSince(start))
    }

    init(file:FileInfo, handler: @escaping ((Error?) -> Void)) {
        self.file = file
        self.handler = handler
    }
    
    override func start() {
        if isCancelled {
            finish()
            return
        }
        
        // Request background execution time so the upload can finish if the app
        // is briefly backgrounded (~30s). When this expires, we only end the
        // background task — we do NOT cancel in-flight operations.
        if let app = extensionSafeApplication() {
            backgroundTaskId = app.beginBackgroundTask(withName: "UploadFile-\(file.id)") { [weak self] in
                guard let self = self else { return }
                self.logger.warning("Background task expired for file: \(self.file.name, privacy: .public)")
                extensionSafeApplication()?.endBackgroundTask(self.backgroundTaskId)
                self.backgroundTaskId = .invalid
            }
        }

        operationStartTime = Date()
        flowLogger.info("[START] t=0.0s file=\(self.file.name, privacy: .public) id=\(self.file.id, privacy: .public) url=\(self.file.url.path, privacy: .public)")

        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.restartStaleAPICallIfNeeded()
        }

        getPresignedUrl { [self] in
            uploadFileDataToS3 { [self] in
                registerRecord()
            }
        }

        super.start()
    }

    private func restartStaleAPICallIfNeeded() {
        guard let startTime = operationStartTime,
              Date().timeIntervalSince(startTime) > 10 else { return }

        if backgroundTaskIdentifier == nil && foregroundUploadTask == nil, let op = getPresignedURLOperation {
            logger.info("Cancelling stale presignedUrl after foreground resume for: \(self.file.name, privacy: .public)")
            op.cancel()
        } else if let task = foregroundUploadTask {
            logger.info("Cancelling stale foreground upload after foreground resume for: \(self.file.name, privacy: .public)")
            task.cancel()
        } else if backgroundTaskIdentifier != nil, let op = registerRecordOperation {
            logger.info("Cancelling stale registerRecord after foreground resume for: \(self.file.name, privacy: .public)")
            op.cancel()
        }
    }
    
    override func finish() {
        flowLogger.info("[FINISH] t=\(self.elapsed, privacy: .public)s file=\(self.file.name, privacy: .public) error=\(self.error.map { String(describing: $0) } ?? "none", privacy: .public)")

        progressObservation?.invalidate()
        progressObservation = nil

        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
            foregroundObserver = nil
        }

        super.finish()

        if !didSentFinishNotification {
            DispatchQueue.main.async {
                let userInfo: [String: Any]?
                if let error = self.error {
                    userInfo = ["error": error]
                    self.file.didFailUpload = true
                } else {
                    userInfo = nil
                }
                
                NotificationCenter.default.post(name: Self.uploadFinishedNotification, object: self, userInfo: userInfo)
            }
        }
        
        // End the background task when the upload finishes
        if backgroundTaskId != .invalid {
            extensionSafeApplication()?.endBackgroundTask(backgroundTaskId)
            backgroundTaskId = .invalid
        }
    }
    
    override func cancel() {
        super.cancel()

        getPresignedURLOperation?.cancel()
        registerRecordOperation?.cancel()
        foregroundUploadTask?.cancel()
        if let taskId = backgroundTaskIdentifier {
            BackgroundUploadSessionManager.shared.removeCompletionHandler(forTaskIdentifier: taskId)
        }
        
        DispatchQueue.main.async {
            let userInfo: [String: Any]?
            if let error = self.error {
                userInfo = ["error": error]
                self.file.didFailUpload = true
            } else {
                userInfo = nil
            }
            
            NotificationCenter.default.post(name: Self.uploadFinishedNotification, object: self, userInfo: userInfo)
            
            self.handler(nil)
        }
        
        didSentFinishNotification = true
        
        finish()
    }
    
    private func getPresignedUrl(success: @escaping (() -> Void)) {
        phaseStartTime = Date()
        let fileExists = FileManager.default.fileExists(atPath: file.url.path)
        flowLogger.info("[PHASE 1] t=\(self.elapsed, privacy: .public)s getPresignedUrl started — fileExists=\(fileExists, privacy: .public) path=\(self.file.url.path, privacy: .public)")

        guard let resources = try? file.url.resourceValues(forKeys:[.fileSizeKey]),
              let fileSize = resources.fileSize else {
            flowLogger.error("[PHASE 1 FAILED] t=\(self.elapsed, privacy: .public)s Cannot get file size for: \(self.file.name, privacy: .public)")
            error = UploadError.presignedURL
            handler(UploadError.presignedURL)
            finish()
            return
        }
        
        logger.debug("Getting presigned URL for file: \(self.file.name, privacy: .public), size: \(fileSize, privacy: .public) bytes")
        
        let mimeType = (file.url.mimeType ?? "application/octet-stream")
        let params: GetPresignedUrlParams = GetPresignedUrlParams(file.folder.folderId, file.folder.folderLinkId, mimeType, file.name, fileSize, nil)
        
        let apiOperation = APIOperation(FilesEndpoint.getPresignedUrl(params: params))
        apiOperation.execute(in: APIRequestDispatcher()) { [self] result in
            guard isCancelled == false else { return }
            
            switch result {
            case .json(let response, _):
                guard let model: GetPresignedUrlResponse = JSONHelper.convertToModel(from: response) else {
                    error = UploadError.presignedURL
                    handler(UploadError.presignedURL)
                    finish()
                    return
                }

                if model.isSuccessful == true,
                   let voValue = model.results?.first?.data?.first?.simpleVO?.value,
                   let s3Url = voValue.presignedPost?.url,
                   let destinationUrl = voValue.destinationUrl,
                   let fields = voValue.presignedPost?.fields {
                    self.s3Url = s3Url
                    self.destinationUrl = destinationUrl
                    self.fields = fields
                    self.flowLogger.info("[PHASE 1 OK] t=\(self.elapsed, privacy: .public)s dur=\(self.phaseDuration, privacy: .public)s s3Url=\(s3Url, privacy: .public)")
                    success()
                } else if model.isSuccessful == false, model.results?.first?.data == nil {
                    self.flowLogger.error("[PHASE 1 AUTH] t=\(self.elapsed, privacy: .public)s session invalid for: \(self.file.name, privacy: .public)")
                    error = UploadError.authenticationRequired
                    handler(UploadError.authenticationRequired)
                    finish()
                } else {
                    self.flowLogger.error("[PHASE 1 FAILED] t=\(self.elapsed, privacy: .public)s presignedUrl response unsuccessful for: \(self.file.name, privacy: .public)")
                    error = UploadError.presignedURL
                    handler(UploadError.presignedURL)
                    finish()
                }
            case .error(let err, _):
                self.flowLogger.error("[PHASE 1 FAILED] t=\(self.elapsed, privacy: .public)s presignedUrl network error: \(err.debugDescription, privacy: .public)")
                self.error = UploadError.presignedURL
                handler(UploadError.presignedURL)
                finish()
            default:
                finish()
                break
            }
        }
    }
    
    private func uploadFileDataToS3(success: @escaping (() -> Void)) {
        phaseStartTime = Date()
        flowLogger.info("[PHASE 2] t=\(self.elapsed, privacy: .public)s S3 upload started for: \(self.file.name, privacy: .public)")
        var contentLength = prefixData.count
        let resources = try! file.url.resourceValues(forKeys:[.fileSizeKey, .creationDateKey])
        let fileSize = resources.fileSize!
        contentLength += fileSize
        contentLength += "\r\n--\(boundary)--".data(using: .utf8)!.count

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"

        let creationDate = resources.creationDate!
        createdDT = dateFormatter.string(from: creationDate)

        var uploadRequest = URLRequest(url: URL(string: s3Url)!)
        uploadRequest.timeoutInterval = 86400
        uploadRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "content-type")
        uploadRequest.addValue("\(contentLength)", forHTTPHeaderField: "Content-Length")
        uploadRequest.httpMethod = "POST"

        // Build multipart body into a temp file in the app group container
        // so it survives app termination.
        let tempURL = BackgroundUploadSessionManager.uploadTempDirectory.appendingPathComponent(UUID().uuidString)
        let outputStream = OutputStream(url: tempURL, append: false)!
        outputStream.open()

        var buffer = [UInt8](repeating: 0, count: 1024 * 64)

        let prefixStream = InputStream(data: prefixData)
        prefixStream.open()
        while prefixStream.hasBytesAvailable {
            let bytesRead = prefixStream.read(&buffer, maxLength: buffer.count)
            if bytesRead > 0 { outputStream.write(buffer, maxLength: bytesRead) } else { break }
        }
        prefixStream.close()

        let fileStream = InputStream(url: file.url)!
        fileStream.open()
        while fileStream.hasBytesAvailable {
            let bytesRead = fileStream.read(&buffer, maxLength: buffer.count)
            if bytesRead > 0 { outputStream.write(buffer, maxLength: bytesRead) } else { break }
        }
        fileStream.close()

        let postfixStream = InputStream(data: "\r\n--\(boundary)--".data(using: .utf8)!)
        postfixStream.open()
        while postfixStream.hasBytesAvailable {
            let bytesRead = postfixStream.read(&buffer, maxLength: buffer.count)
            if bytesRead > 0 { outputStream.write(buffer, maxLength: bytesRead) } else { break }
        }
        postfixStream.close()
        outputStream.close()

        let tempFileSize = (try? FileManager.default.attributesOfItem(atPath: tempURL.path)[.size] as? Int) ?? -1
        flowLogger.info("[PHASE 2] t=\(self.elapsed, privacy: .public)s tempFile: size=\(tempFileSize, privacy: .public) contentLength=\(contentLength, privacy: .public) match=\(tempFileSize == contentLength, privacy: .public)")

        if UploadManager.shared.isInForeground {
            // Fast foreground upload — uses default URLSession, ~10x faster than background daemon
            foregroundTempFileURL = tempURL
            let task = Self.foregroundSession.uploadTask(with: uploadRequest, fromFile: tempURL) { [weak self] _, response, error in
                guard let self = self, !self.isCancelled else { return }

                // Clean up temp file
                if let tempPath = self.foregroundTempFileURL {
                    try? FileManager.default.removeItem(at: tempPath)
                }
                self.foregroundUploadTask = nil

                if let error = error {
                    self.flowLogger.error("[PHASE 2 FAILED] t=\(self.elapsed, privacy: .public)s dur=\(self.phaseDuration, privacy: .public)s foreground error=\(error.localizedDescription, privacy: .public)")
                    self.error = .s3
                    self.handler(UploadError.s3)
                    self.finish()
                } else if let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) {
                    self.flowLogger.info("[PHASE 2 OK] t=\(self.elapsed, privacy: .public)s dur=\(self.phaseDuration, privacy: .public)s foreground upload completed")
                    success()
                } else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    self.flowLogger.error("[PHASE 2 FAILED] t=\(self.elapsed, privacy: .public)s dur=\(self.phaseDuration, privacy: .public)s foreground status=\(statusCode, privacy: .public)")
                    self.error = .s3
                    self.handler(UploadError.s3)
                    self.finish()
                }
            }
            foregroundUploadTask = task

            progressObservation = task.progress.observe(\.fractionCompleted) { [weak self] taskProgress, _ in
                guard let self = self else { return }
                let fraction = taskProgress.fractionCompleted
                self.progress = fraction

                DispatchQueue.main.async {
                    let userInfo: [String: Any] = ["fileInfoId": self.file.id, "progress": fraction]
                    NotificationCenter.default.post(name: Self.uploadProgressNotification, object: nil, userInfo: userInfo)

                    let queueIndex = UploadManager.shared.uploadQueue.operations
                        .compactMap { $0 as? UploadOperation }
                        .firstIndex(where: { $0.file.id == self.file.id })
                    let fileIndex = (queueIndex ?? 0) + 1

                    UploadLiveActivityManager.shared.updateProgress(
                        fileInfoId: self.file.id,
                        fileName: self.file.name,
                        fileIndex: fileIndex,
                        fileProgress: fraction
                    )
                }
            }

            task.resume()
            flowLogger.info("[PHASE 2] t=\(self.elapsed, privacy: .public)s foreground upload task started for: \(self.file.name, privacy: .public)")
        } else {
            // Background-resilient upload — slower but survives app suspension/termination
            let metadata = BackgroundUploadMetadata(
                fileInfoId: file.id,
                fileName: file.name,
                s3Url: s3Url,
                destinationUrl: destinationUrl,
                createdDT: createdDT,
                folderId: file.folder.folderId,
                folderLinkId: file.folder.folderLinkId,
                tempFilePath: tempURL.path,
                taskIdentifier: 0
            )

            backgroundTaskIdentifier = BackgroundUploadSessionManager.shared.startUpload(
                request: uploadRequest,
                fileURL: tempURL,
                metadata: metadata
            ) { [weak self] error in
                guard let self = self, !self.isCancelled else { return }

                if let error = error {
                    self.flowLogger.error("[PHASE 2 FAILED] t=\(self.elapsed, privacy: .public)s dur=\(self.phaseDuration, privacy: .public)s background error=\(error.localizedDescription, privacy: .public)")
                    self.error = .s3
                    self.handler(UploadError.s3)
                    self.finish()
                } else {
                    self.flowLogger.info("[PHASE 2 OK] t=\(self.elapsed, privacy: .public)s dur=\(self.phaseDuration, privacy: .public)s background upload completed")
                    success()
                }
            }

            flowLogger.info("[PHASE 2] t=\(self.elapsed, privacy: .public)s background upload task \(self.backgroundTaskIdentifier ?? -1, privacy: .public) started for: \(self.file.name, privacy: .public)")
        }
    }
    
    private func registerRecord() {
        let registerStartTime = Date()
        let params = RegisterRecordParams(file.folder.folderId, file.folder.folderLinkId, file.name, createdDT, s3Url, destinationUrl)

        phaseStartTime = Date()
        flowLogger.info("[PHASE 3] t=\(self.elapsed, privacy: .public)s registerRecord started — folderId=\(self.file.folder.folderId, privacy: .public) destinationUrl=\(self.destinationUrl ?? "nil", privacy: .public)")
        
        let apiOperation = APIOperation(FilesEndpoint.registerRecord(params: params))
        apiOperation.execute(in: APIRequestDispatcher()) { [self] result in
            guard isCancelled == false else { return }
            
            // Calculate and notify about registerRecord response time
            let registerTime = Date().timeIntervalSince(registerStartTime)
            logger.info("registerRecord response time: \(registerTime, privacy: .public) seconds for file: \(self.file.name, privacy: .public)")
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Self.registerRecordTimingNotification,
                    object: self,
                    userInfo: ["registerTime": registerTime]
                )
            }
            
            switch result {
            case .json(let response, _):
                guard let model: UploadFileMetaResponse = JSONHelper.convertToModel(from: response) else {
                    logger.error("Failed to convert registerRecord response to model for file: \(self.file.name, privacy: .public)")
                    self.error = UploadError.registerRecord
                    handler(UploadError.registerRecord)
                    finish()
                    return
                }

                if model.isSuccessful == true {
                    flowLogger.info("[PHASE 3 OK] t=\(self.elapsed, privacy: .public)s dur=\(self.phaseDuration, privacy: .public)s registerRecord succeeded")
                    uploadedFile = model.results?.first?.data?.first?.recordVO
                    UploadManager.markFileAsCompleted(fileId: self.file.id)
                    handler(nil)
                    finish()
                } else {
                    flowLogger.error("[PHASE 3 FAILED] t=\(self.elapsed, privacy: .public)s dur=\(self.phaseDuration, privacy: .public)s registerRecord unsuccessful")
                    self.error = UploadError.registerRecord
                    handler(UploadError.registerRecord)
                    finish()
                }
            case .error(let error, _):
                flowLogger.error("[PHASE 3 FAILED] t=\(self.elapsed, privacy: .public)s dur=\(self.phaseDuration, privacy: .public)s network error: \(error.debugDescription, privacy: .public)")
                self.error = UploadError.registerRecord
                handler(UploadError.registerRecord)
                finish()
            default:
                flowLogger.error("[PHASE 3 FAILED] t=\(self.elapsed, privacy: .public)s unexpected result type")
                finish()
                break
            }
        }
    }
}

// MARK: - Upload request body methods
extension UploadOperation {
    private func getHttpBody() -> Data {
        var body = Data()

        for (key, value) in fields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        let mimeType = (file.url.mimeType ?? "application/octet-stream")
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"Content-Type\"\r\n\r\n".data(using: .utf8)!)
        body.append(mimeType.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(file.name)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)

        return body
    }
}

