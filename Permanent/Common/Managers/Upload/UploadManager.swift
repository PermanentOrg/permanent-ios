//
//  UploadManager.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/10/2020.
//

import Foundation
import UIKit
import os.log

class UploadManager {
    static let didRefreshQueueNotification = Notification.Name("UploadManager.didRefreshQueueNotification")
    static let didUploadFileNotification = Notification.Name("UploadManager.didUploadFileNotification")
    static let quotaExceededNotification = Notification.Name("UploadManager.quotaExceededNotification")
    static let didCreateMobileUploadsFolderNotification = Notification.Name("UploadManager.didCreateMobileUploadsFolderNotification")
    
    static let shared: UploadManager = UploadManager()
    
    let uploadQueue: OperationQueue = OperationQueue()
    
    var timer: Timer?
    
    // Track registerRecord timing for dynamic concurrency adjustment.
    // Cap of 10 is the upper bound — the dynamic throttle scales back down
    // when registerRecord avg time exceeds 6 s (2× the optimal threshold),
    // so a slow server keeps us at 3-5. Threshold of 3 s only ramps up when
    // the API is genuinely fast.
    private var recentRegisterTimes: [TimeInterval] = []
    private let minConcurrentUploads = 1
    private let maxConcurrentUploads = 10
    private let defaultConcurrentUploads = 1
    private let optimalRegisterTimeThreshold: TimeInterval = 3
    private let maxRegisterTimesToTrack = 5 // Track the last 5 register times
    
    private let logger = Logger(subsystem: "com.permanent.ios", category: "UploadManager")
    private let flowLogger = Logger(subsystem: "com.permanent.ios", category: "UploadFlow")

    /// True for `URLError`s caused by connectivity loss / handoff, not server
    /// faults. Such failures shouldn't burn retry attempts — they'll recover
    /// when the device is back online.
    static func isTransientNetworkError(_ error: Error?) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed,
             .internationalRoamingOff, .dataNotAllowed, .resourceUnavailable:
            return true
        default:
            return false
        }
    }

    init() {
        uploadQueue.maxConcurrentOperationCount = defaultConcurrentUploads

        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(refreshQueue), userInfo: nil, repeats: true)

        // Listen for upload completion notifications
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(handleUploadFinished(_:)),
                                              name: UploadOperation.uploadFinishedNotification,
                                              object: nil)

        // Listen for registerRecord timing notifications
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(handleRegisterRecordTiming(_:)),
                                              name: NSNotification.Name("UploadOperation.registerRecordTimingNotification"),
                                              object: nil)

        // Immediately re-queue any pending uploads when the app returns to foreground
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(appWillEnterForeground),
                                              name: UIApplication.willEnterForegroundNotification,
                                              object: nil)

        NotificationCenter.default.addObserver(self,
                                              selector: #selector(appDidEnterBackground),
                                              name: UIApplication.didEnterBackgroundNotification,
                                              object: nil)

        logger.info("🔼 UploadManager initialized with \(self.uploadQueue.maxConcurrentOperationCount, privacy: .public) concurrent uploads")
    }

    @objc private func appDidEnterBackground() {
        // Throttle concurrency while iOS is giving us limited runtime via
        // `beginBackgroundTask`. 3 keeps a reasonable upload pace without
        // burning the budget on too many parallel Phase 1/3 API calls.
        uploadQueue.maxConcurrentOperationCount = 3
        logger.info("🔼 App entered background — limiting to 3 concurrent uploads")

        // Ask iOS to wake us later so the queue can keep draining once the
        // foreground beginBackgroundTask budget expires.
        BackgroundUploadDrainTask.schedule()
    }

    /// True while any operation is still in-flight or any file remains in the
    /// persisted queue. Drives whether we should keep a BGProcessingTask wake
    /// request pending.
    var hasPendingWork: Bool {
        if uploadQueue.operations.contains(where: { !$0.isFinished }) { return true }
        if let saved: [FileInfo] = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey),
           !saved.isEmpty {
            return true
        }
        return false
    }

    @objc private func appWillEnterForeground() {
        uploadQueue.maxConcurrentOperationCount = defaultConcurrentUploads
        logger.info("🔼 App entering foreground — restored concurrent uploads to \(self.defaultConcurrentUploads, privacy: .public)")
        refreshQueue()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleRegisterRecordTiming(_ notification: Notification) {
        if let registerTime = notification.userInfo?["registerTime"] as? TimeInterval {
            // Add this register time to our tracking array
            recentRegisterTimes.append(registerTime)
            
            // Keep only the most recent register times
            if recentRegisterTimes.count > maxRegisterTimesToTrack {
                recentRegisterTimes.removeFirst()
            }
            
            // Adjust concurrency based on register times
            adjustConcurrentUploadsBasedOnTiming()
        }
    }
    
    @objc private func handleUploadFinished(_ notification: Notification) {
        // If there was an error, decrease concurrency
        if notification.userInfo?["error"] as? Error != nil {
            decreaseConcurrentUploads()
        }
    }
    
    private func adjustConcurrentUploadsBasedOnTiming() {
        guard !recentRegisterTimes.isEmpty else { return }
        
        // Calculate average register time
        let averageRegisterTime = recentRegisterTimes.reduce(0, +) / Double(recentRegisterTimes.count)
        
        // If register responses are faster than our threshold, we can increase concurrency
        if averageRegisterTime < optimalRegisterTimeThreshold {
            increaseConcurrentUploads()
        } 
        // If register responses are taking longer than our threshold, decrease concurrency
        else if averageRegisterTime > optimalRegisterTimeThreshold * 2 {
            decreaseConcurrentUploads()
        }
        // Otherwise, keep current concurrency
        
        logger.debug("🔼 Average registerRecord time: \(averageRegisterTime, privacy: .public) seconds, Concurrent uploads: \(self.uploadQueue.maxConcurrentOperationCount, privacy: .public)")
    }
    
    private func increaseConcurrentUploads() {
        let current = uploadQueue.maxConcurrentOperationCount
        if current < maxConcurrentUploads {
            uploadQueue.maxConcurrentOperationCount = current + 1
            logger.debug("🔼 Increased concurrent uploads to: \(self.uploadQueue.maxConcurrentOperationCount, privacy: .public)")
        }
    }
    
    private func decreaseConcurrentUploads() {
        let current = uploadQueue.maxConcurrentOperationCount
        if current > minConcurrentUploads {
            uploadQueue.maxConcurrentOperationCount = current - 1
            logger.debug("🔼 Decreased concurrent uploads to: \(self.uploadQueue.maxConcurrentOperationCount, privacy: .public)")
        }
    }
    
    func upload(files: [FileInfo], completion: ((Bool) -> Void)? = nil) {
        var filesSize = 0
        files.forEach { file in
            if let resources = try? file.url.resourceValues(forKeys: [.fileSizeKey]) {
                filesSize += resources.fileSize!
            } else if let fileContents = file.fileContents {
                filesSize += fileContents.count
            }
        }

        logger.debug("Preparing to upload \(files.count, privacy: .public) files with total size: \(filesSize, privacy: .public) bytes")

        // Call AccountAPI and figure if there's enough space left
        guard let accountId: Int = PermSession.currentSession?.account.accountID else {
            logger.error("🔼 No active session found")
            DispatchQueue.main.async { completion?(false) }
            return
        }

        let getUserDataOperation = APIOperation(AccountEndpoint.getUserData(accountId: accountId))
        getUserDataOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<AccountVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    self.logger.error("🔼 Failed to get user data")
                    DispatchQueue.main.async { completion?(false) }
                    return
                }

                if model.results[0].data?[0].accountVO?.spaceLeft ?? 0 > filesSize {
                    // Light, immediate UI work on main: stamp the queue owner
                    // and start the Live Activity so the user gets visible
                    // confirmation right away.
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(accountId, forKey: Constants.Keys.StorageKeys.uploadQueueOwnerAccountIdKey)

                        let archiveNo = PermSession.currentSession?.selectedArchive?.archiveNbr ?? ""
                        let folderLinkId = files.first?.folder.folderLinkId ?? 0
                        UploadLiveActivityManager.shared.startActivity(
                            totalFiles: files.count,
                            firstFileName: files.first?.name ?? "",
                            archiveNo: archiveNo,
                            folderLinkId: folderLinkId
                        )
                    }

                    // File-system prep (saveFile from contents / tmp→durable
                    // move) on a background queue so the spinner can keep
                    // animating. Critically: NO `uploadFilesKey` access here —
                    // all UserDefaults read/write happens on main only, which
                    // serializes us against the 30 s `refreshQueue` timer and
                    // avoids the lost-update race that hit at 900-file scale.
                    DispatchQueue.global(qos: .userInitiated).async {
                        let fileHelper = FileHelper()
                        for file in files {
                            self.prepareFileForUpload(file, fileHelper: fileHelper)
                        }

                        // Single read-append-write on main. O(N) instead of
                        // the previous O(N²) per-file decode/encode loop.
                        DispatchQueue.main.async {
                            var saved: [FileInfo] = (try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)) ?? []
                            let existingIds = Set(saved.map(\.id))
                            for file in files where !existingIds.contains(file.id) {
                                saved.append(file)
                            }
                            try? PreferencesManager.shared.setCustomObject(saved, forKey: Constants.Keys.StorageKeys.uploadFilesKey)

                            self.refreshQueue()
                            completion?(true)
                        }
                    }
                } else {
                    self.logger.error("🔼 Quota exceeded - not enough space left")
                    NotificationCenter.default.post(name: Self.quotaExceededNotification, object: self, userInfo: nil)
                    DispatchQueue.main.async { completion?(false) }
                }

                return

            case .error(let error, _):
                self.logger.error("🔼 Error getting user data: \(error?.localizedDescription ?? "unknown", privacy: .public)")
                DispatchQueue.main.async { completion?(false) }
                return

            default:
                self.logger.error("🔼 Unexpected result type from getUserData")
                DispatchQueue.main.async { completion?(false) }
                break
            }
        }
    }
    
    /// File-system prep only (writes in-memory bytes to disk; moves tmp files
    /// to durable storage). Does NOT touch `uploadFilesKey` — the caller is
    /// responsible for persistence and must do it on main to avoid racing the
    /// 30 s `refreshQueue` timer.
    private func prepareFileForUpload(_ file: FileInfo, fileHelper: FileHelper) {
        if let fileContents = file.fileContents {
            file.url = fileHelper.saveFile(fileContents, named: file.id, withExtension: "jpeg", isDownload: false) ?? URL(fileURLWithPath: "")
            file.fileContents = nil
        } else if file.url.path.contains("/tmp/"), let uploadDir = fileHelper.uploadDirectoryURL {
            // iOS purges tmp/ when the app is backgrounded, destroying queued
            // files that haven't started uploading yet.
            let durableURL = uploadDir.appendingPathComponent(file.id).appendingPathExtension(file.url.pathExtension)
            do {
                if FileManager.default.fileExists(atPath: durableURL.path) {
                    try FileManager.default.removeItem(at: durableURL)
                }
                try FileManager.default.moveItem(at: file.url, to: durableURL)
                file.url = durableURL
            } catch {
                logger.error("🔼 Failed to move file from tmp to durable location: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    @objc
    func refreshQueue() {
        if uploadQueue.isSuspended, PermSession.currentSession != nil {
            logger.info("🔼 Session restored — resuming upload queue")
            uploadQueue.isSuspended = false
        }

        // If a different account is now logged in than the one that owned the
        // persisted upload queue, wipe the queue. Otherwise we'd silently
        // upload User A's files into User B's archive (the server might
        // accept the call with the new bearer token but the folderLinkId
        // belongs to User A).
        if let currentAccountId = PermSession.currentSession?.account.accountID {
            let ownerKey = Constants.Keys.StorageKeys.uploadQueueOwnerAccountIdKey
            if let ownerAccountId = UserDefaults.standard.object(forKey: ownerKey) as? Int,
               ownerAccountId != currentAccountId,
               let savedFiles: [FileInfo] = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey),
               !savedFiles.isEmpty {
                logger.warning("🔼 Account changed (\(ownerAccountId, privacy: .public) → \(currentAccountId, privacy: .public)) — wiping stale upload queue of \(savedFiles.count, privacy: .public) files")
                cancelAll()
                UserDefaults.standard.set(currentAccountId, forKey: ownerKey)
                return
            }
            // No mismatch — re-stamp in case it was missing (older builds).
            UserDefaults.standard.set(currentAccountId, forKey: ownerKey)
        }



        do {
            let selectedArchive = PermSession.currentSession?.selectedArchive
            let extensionUploads = try ExtensionUploadManager.shared.savedFiles()
            let selectedArchiveUploads = extensionUploads.filter({ $0.archiveId == selectedArchive?.archiveID })
            
            if selectedArchiveUploads.isEmpty == false {
                logger.info("🔼 Found \(selectedArchiveUploads.count, privacy: .public) files from extension to upload")

                upload(files: selectedArchiveUploads)
                try ExtensionUploadManager.shared.clearSavedFiles(selectedArchiveUploads)
            } else if !extensionUploads.isEmpty {
                logger.info("🔼 Found \(extensionUploads.count, privacy: .public) extension files but none match current archive ID: \(selectedArchive?.archiveID ?? -1, privacy: .public)")
            }
        } catch {
            logger.error("🔼 Error refreshing upload queue: \(error.localizedDescription, privacy: .public)")
        }
        
        DispatchQueue.main.async { [self] in
            var didRefresh = false
            
            var savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)

            // Fix file URLs invalidated by iOS sandbox container UUID change after app restart.
            if let files = savedFiles {
                let fileHelper = FileHelper()
                var urlsUpdated = false
                var removedIds: [String] = []
                for file in files {
                    guard !FileManager.default.fileExists(atPath: file.url.path) else { continue }
                    let fileName = file.url.lastPathComponent
                    if let uploadDir = fileHelper.uploadDirectoryURL {
                        let reconstructed = uploadDir.appendingPathComponent(fileName)
                        if FileManager.default.fileExists(atPath: reconstructed.path) {
                            file.url = reconstructed
                            urlsUpdated = true
                        } else {
                            self.logger.warning("🔼 File missing after restart, removing from queue: \(file.name, privacy: .public)")
                            removedIds.append(file.id)
                        }
                    }
                }
                if !removedIds.isEmpty {
                    savedFiles?.removeAll { removedIds.contains($0.id) }
                    urlsUpdated = true
                    // Notify the LA that these files were silently dropped so
                    // its totalFiles counter doesn't wait forever on phantoms.
                    for _ in removedIds {
                        UploadLiveActivityManager.shared.fileCancelled()
                    }
                }
                if urlsUpdated {
                    try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                }
            }

            // Remove files that were already successfully uploaded (duplicate prevention).
            // This handles the case where registerRecord succeeded but the app was force-quit
            // before the main-queue cleanup could remove the file from the persisted queue.
            let completedIds = UserDefaults.standard.stringArray(forKey: Constants.Keys.StorageKeys.completedUploadFileIdsKey) ?? []
            if !completedIds.isEmpty, let files = savedFiles {
                let duplicateIds = files.filter { completedIds.contains($0.id) }.map(\.id)
                if !duplicateIds.isEmpty {
                    logger.info("🔼 Removing \(duplicateIds.count, privacy: .public) already-completed files from persisted queue")
                    for id in duplicateIds {
                        if let url = files.first(where: { $0.id == id })?.url {
                            FileHelper().deleteFile(at: url)
                        }
                        Self.removeCompletedFileId(id)
                    }
                    savedFiles?.removeAll(where: { duplicateIds.contains($0.id) })
                    try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                    // Notify the LA — these files were "completed" elsewhere
                    // but our counter doesn't know about them. fileCancelled
                    // decrements totalFiles so the LA isn't stuck waiting.
                    for _ in duplicateIds {
                        UploadLiveActivityManager.shared.fileCancelled()
                    }
                }
            }
            
            // Clear the completed + in-flight sets + folder cache when no
            // files remain. Otherwise stale Phase 3 in-flight markers would
            // trigger unnecessary navigateMin lookups on the next batch.
            if savedFiles?.isEmpty != false {
                Self.clearCompletedFileIds()
                Self.clearPhase3InFlightIds()
                self.clearFolderListingCache()
            }
            
            // Only count operations that are still live — finished ones can linger
            // in the queue briefly and would otherwise block retries by colliding
            // on `file.id`. Also skip files still being drained from a legacy
            // background URLSession session (one-time migration after the bg
            // pipeline was removed).
            let uploadNames = uploadQueue.operations.filter { !$0.isFinished }.compactMap(\.name)
            let drainingBackgroundFileIds = Set(BackgroundUploadMetadata.loadAll().map(\.fileInfoId))
            for file in savedFiles ?? [] where uploadNames.contains(file.id) == false && !drainingBackgroundFileIds.contains(file.id) {
                let uploadOperation = UploadOperation(file: file) { error in
                    DispatchQueue.main.async {
                        var savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                        savedFiles?.removeAll(where: { $0.id == file.id })

                        if error == nil {
                            FileHelper().deleteFile(at: file.url)

                            try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                            UploadLiveActivityManager.shared.fileCompleted(success: true)

                            // Keep a wake request pending while work remains; pull it once empty.
                            if self.hasPendingWork {
                                BackgroundUploadDrainTask.schedule()
                            } else {
                                BackgroundUploadDrainTask.cancel()
                            }
                        } else if (error as? UploadError) == .authenticationRequired {
                            self.flowLogger.error("🔼 [HANDLER] AUTH FAILED file=\(file.name, privacy: .public) id=\(file.id, privacy: .public) — suspending queue, re-queuing without retry")
                            if var savedFiles = savedFiles {
                                savedFiles.append(file)
                                try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                            } else {
                                try? PreferencesManager.shared.setCustomObject([file], forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                            }
                            self.uploadQueue.isSuspended = true
                        } else {
                            file.didFailUpload = true
                            let maxRetries = 3
                            let isTransientNetworkError = Self.isTransientNetworkError(error)

                            // Network errors don't count toward the retry cap — they recover
                            // when connectivity does. Use a longer backoff to give the network
                            // time to stabilise (Wi-Fi/cellular handoff can take 5–30s).
                            if isTransientNetworkError {
                                self.flowLogger.error("🔼 [HANDLER] NETWORK file=\(file.name, privacy: .public) id=\(file.id, privacy: .public) error=\(error?.localizedDescription ?? "unknown", privacy: .public) — re-queuing without counting retry")
                                if var savedFiles = savedFiles {
                                    savedFiles.append(file)
                                    try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                                } else {
                                    try? PreferencesManager.shared.setCustomObject([file], forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                                }
                                // Re-queue synchronously — the new background URLSession task
                                // will park itself via `waitsForConnectivity` until the network
                                // is back, which works correctly even if iOS suspends us next.
                                self.refreshQueue()
                            } else {
                                file.retryCount += 1

                                if file.retryCount <= maxRetries {
                                    self.flowLogger.error("🔼 [HANDLER] FAILED file=\(file.name, privacy: .public) id=\(file.id, privacy: .public) error=\(error?.localizedDescription ?? "unknown", privacy: .public) — re-queuing (attempt \(file.retryCount)/\(maxRetries))")
                                    if var savedFiles = savedFiles {
                                        savedFiles.append(file)
                                        try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                                    } else {
                                        try? PreferencesManager.shared.setCustomObject([file], forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                                    }
                                    self.refreshQueue()
                                } else {
                                    self.flowLogger.error("🔼 [HANDLER] FAILED file=\(file.name, privacy: .public) id=\(file.id, privacy: .public) — max retries reached, dropping from queue")
                                    try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                                    FileHelper().deleteFile(at: file.url)
                                    UploadLiveActivityManager.shared.fileCompleted(success: false)
                                }
                            }
                        }

                        NotificationCenter.default.post(name: Self.didUploadFileNotification, object: nil, userInfo: ["file": file])
                    }
                }
                uploadOperation.name = file.id
                
                uploadQueue.addOperation(uploadOperation)
                logger.debug("Added file to upload queue: \(file.name, privacy: .public)")
                
                didRefresh = true
            }
            
            if didRefresh {
                logger.info("🔼 Refreshed upload queue with new files")
                
                // Start a new Live Activity only when re-queuing after app relaunch
                // (i.e. no activity exists yet). If one already exists (from upload(files:)),
                // don't double-count by calling startActivity again.
                if !UploadLiveActivityManager.shared.isActive {
                    let reQueuedOps = uploadQueue.operations
                        .compactMap { $0 as? UploadOperation }
                        .filter { !$0.isFinished && !$0.isCancelled }
                    if !reQueuedOps.isEmpty {
                        let archiveNo = PermSession.currentSession?.selectedArchive?.archiveNbr ?? ""
                        let folderLinkId = reQueuedOps.first?.file.folder.folderLinkId ?? 0
                        UploadLiveActivityManager.shared.startActivity(
                            totalFiles: reQueuedOps.count,
                            firstFileName: reQueuedOps.first?.file.name ?? "",
                            archiveNo: archiveNo,
                            folderLinkId: folderLinkId
                        )
                    }
                }
                
                NotificationCenter.default.post(name: Self.didRefreshQueueNotification, object: nil, userInfo: nil)
            }
        }
    }
    
    func cancelUpload(fileId: String) {
        logger.info("🔼 Cancelling upload for file ID: \(fileId, privacy: .public)")
        
        var savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        
        let fileURL = savedFiles?.first(where: { $0.id == fileId })?.url
        
        savedFiles?.removeAll(where: { $0.id == fileId })
        try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        
        uploadQueue.operations.first(where: { $0.name == fileId })?.cancel()
        
        if let fileURL = fileURL {
            FileHelper().deleteFile(at: fileURL)
        }
        
        UploadLiveActivityManager.shared.fileCancelled()
    }
    
    func cancelAll() {
        logger.info("🔼 Cancelling all uploads")

        // Read the persisted queue BEFORE clearing it so we can delete the
        // backing files on disk. Operations in `uploadQueue.operations` are a
        // subset of the persisted list — anything that was queued but never
        // got an UploadOperation (e.g. files added during a backgrounded
        // window) would otherwise leak forever.
        let persistedFiles: [FileInfo] = (try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)) ?? []
        let inFlightFiles = uploadQueue.operations.compactMap { ($0 as? UploadOperation)?.file }

        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        UserDefaults.standard.removeObject(forKey: Constants.Keys.StorageKeys.uploadQueueOwnerAccountIdKey)
        Self.clearCompletedFileIds()
        Self.clearPhase3InFlightIds()
        clearFolderListingCache()

        uploadQueue.cancelAllOperations()

        // Union of both sets, deduped by id.
        var seenIds = Set<String>()
        let allFiles = (inFlightFiles + persistedFiles).filter { file in
            guard !seenIds.contains(file.id) else { return false }
            seenIds.insert(file.id)
            return true
        }
        let fileHelper = FileHelper()
        for file in allFiles {
            fileHelper.deleteFile(at: file.url)
        }

        UploadLiveActivityManager.shared.cancelActivity()
    }
    
    func inProgressUpload() -> FileInfo? {
        let executingOp = uploadQueue.operations.first(where: { $0.isExecuting })
        return (executingOp as? UploadOperation)?.file
    }
    
    func queuedFiles() -> [FileInfo] {
        return (try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)) ?? []
    }
    
    func operation(forFileId id: String) -> UploadOperation? {
        return uploadQueue.operations.first(where: { $0.name == id }) as? UploadOperation
    }
    
    // MARK: - Duplicate Upload Prevention
    
    /// Marks a file as completed immediately when registerRecord succeeds.
    /// Uses UserDefaults.synchronize() so the write survives a force-quit.
    static func markFileAsCompleted(fileId: String) {
        let defaults = UserDefaults.standard
        var completedIds = defaults.stringArray(forKey: Constants.Keys.StorageKeys.completedUploadFileIdsKey) ?? []
        guard !completedIds.contains(fileId) else { return }
        completedIds.append(fileId)
        defaults.set(completedIds, forKey: Constants.Keys.StorageKeys.completedUploadFileIdsKey)
        defaults.synchronize()
    }

    /// In-flight duplicate prevention: returns true if `fileId` has already had
    /// a successful registerRecord. UploadOperation checks this at the start of
    /// Phase 3 so a re-queued operation (e.g. after a network handoff) doesn't
    /// create a duplicate archive record for a file that already finished.
    static func isFileAlreadyCompleted(fileId: String) -> Bool {
        let completedIds = UserDefaults.standard.stringArray(forKey: Constants.Keys.StorageKeys.completedUploadFileIdsKey) ?? []
        return completedIds.contains(fileId)
    }
    
    /// Removes a file ID from the completed set (called during cleanup).
    private static func removeCompletedFileId(_ fileId: String) {
        let defaults = UserDefaults.standard
        var completedIds = defaults.stringArray(forKey: Constants.Keys.StorageKeys.completedUploadFileIdsKey) ?? []
        completedIds.removeAll(where: { $0 == fileId })
        defaults.set(completedIds, forKey: Constants.Keys.StorageKeys.completedUploadFileIdsKey)
        defaults.synchronize()
    }
    
    /// Clears the entire completed set (called when the persisted queue is empty).
    private static func clearCompletedFileIds() {
        UserDefaults.standard.removeObject(forKey: Constants.Keys.StorageKeys.completedUploadFileIdsKey)
    }

    // MARK: - Phase 3 in-flight tracking
    //
    // Closes the "server-completed registerRecord but client lost the response"
    // duplicate window. A file is marked in-flight just before registerRecord is
    // issued and only removed on a successful 200. If the request errored (network
    // or otherwise) the entry stays in-flight; subsequent retries consult
    // `fetchFolderContents` to see whether the server already has the record
    // before re-issuing the call (Guard B), and an end-of-batch verification pass
    // does one final reconciliation against the destination folder.

    /// Stored per entry under `inflightPhase3FileIdsKey` (JSON-encoded array).
    /// Carries enough metadata (name + size + createdDT + folder context) for
    /// the end-of-batch verifier to look the record up via `navigateMin` even
    /// after the underlying `FileInfo` has been dropped from `uploadFilesKey`.
    ///
    /// `fileSize` is the canonical match key — it round-trips through the
    /// server exactly (numeric, no formatting). `createdDT` is kept for
    /// diagnostics and as a tiebreaker; it does NOT match exactly because the
    /// server normalises the timezone form when storing/returning it.
    struct Phase3InFlightEntry: Codable {
        let fileId: String
        let fileName: String
        let createdDT: String
        let fileSize: Int64
        let folderLinkId: Int
        let archiveNo: String
    }

    static func phase3InFlightEntries() -> [Phase3InFlightEntry] {
        guard let data = UserDefaults.standard.data(forKey: Constants.Keys.StorageKeys.inflightPhase3FileIdsKey) else {
            return []
        }
        return (try? JSONDecoder().decode([Phase3InFlightEntry].self, from: data)) ?? []
    }

    private static func writePhase3InFlightEntries(_ entries: [Phase3InFlightEntry]) {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: Constants.Keys.StorageKeys.inflightPhase3FileIdsKey)
            defaults.synchronize()
        }
    }

    static func markPhase3InFlight(entry: Phase3InFlightEntry) {
        var entries = phase3InFlightEntries()
        guard !entries.contains(where: { $0.fileId == entry.fileId }) else { return }
        entries.append(entry)
        writePhase3InFlightEntries(entries)
    }

    static func wasPhase3Attempted(fileId: String) -> Bool {
        return phase3InFlightEntries().contains(where: { $0.fileId == fileId })
    }

    static func removePhase3InFlight(fileId: String) {
        var entries = phase3InFlightEntries()
        entries.removeAll { $0.fileId == fileId }
        writePhase3InFlightEntries(entries)
    }

    private static func clearPhase3InFlightIds() {
        UserDefaults.standard.removeObject(forKey: Constants.Keys.StorageKeys.inflightPhase3FileIdsKey)
    }

    // MARK: - End-of-batch verification

    /// Walks the in-flight Phase 3 entries and reconciles each against the
    /// destination folder. For entries whose record *is* present, marks the
    /// file completed (correcting any earlier false-negative). For entries
    /// whose record is *not* present, accepts the failure (drops from the
    /// in-flight set). On API failure of any folder lookup, the corresponding
    /// entries are left intact for the next batch's verification pass.
    ///
    /// Completion: `(found, missed)` counts so the LA can correct its display.
    func verifyInterruptedUploads(completion: @escaping (_ found: Int, _ missed: Int) -> Void) {
        let entries = Self.phase3InFlightEntries()
        guard !entries.isEmpty else {
            completion(0, 0)
            return
        }

        flowLogger.info("🔼 [VERIFY] starting end-of-batch reconciliation for \(entries.count, privacy: .public) in-flight entries")

        // Group by folderLinkId so we make at most one navigateMin call per
        // unique destination folder (the cache also dedupes within 10 s).
        let grouped = Dictionary(grouping: entries, by: \.folderLinkId)
        let group = DispatchGroup()
        var found = 0
        var missed = 0
        let lock = NSLock()

        for (folderLinkId, groupEntries) in grouped {
            group.enter()
            let archiveNo = groupEntries.first?.archiveNo ?? ""
            fetchFolderContents(archiveNo: archiveNo, folderLinkId: folderLinkId) { [weak self] items in
                guard let self = self else { group.leave(); return }
                guard let items = items else {
                    // navigateMin failed for this folder — leave entries
                    // alone so the next verification pass can retry. Do not
                    // remove from the in-flight set, do not adjust counts.
                    for entry in groupEntries {
                        self.flowLogger.warning("🔼 [VERIFY] SKIPPED file=\(entry.fileName, privacy: .public) — folder fetch unreachable, entry retained")
                    }
                    group.leave()
                    return
                }

                for entry in groupEntries {
                    // Shared matcher: see `ItemVOMatching.swift`.
                    let isInFolder = items.record(forUploadName: entry.fileName, size: entry.fileSize) != nil
                    let alreadyCompleted = Self.isFileAlreadyCompleted(fileId: entry.fileId)

                    if isInFolder {
                        if alreadyCompleted {
                            // Entry left behind by a successful retry (Fix 3).
                            // No LA correction needed — already counted as
                            // success inline. Just clean up the marker.
                            self.flowLogger.info("🔼 [VERIFY] FOUND file=\(entry.fileName, privacy: .public) — already counted as success, cleanup only")
                        } else {
                            // File was counted as failed inline but server
                            // actually has it. Correct the LA.
                            self.flowLogger.info("🔼 [VERIFY] FOUND file=\(entry.fileName, privacy: .public) — correcting LA (was counted as failed)")
                            Self.markFileAsCompleted(fileId: entry.fileId)
                            lock.lock(); found += 1; lock.unlock()
                        }
                        Self.removePhase3InFlight(fileId: entry.fileId)
                    } else {
                        self.flowLogger.info("🔼 [VERIFY] MISS file=\(entry.fileName, privacy: .public) — not in folder, accepting failure")
                        Self.removePhase3InFlight(fileId: entry.fileId)
                        if !alreadyCompleted {
                            lock.lock(); missed += 1; lock.unlock()
                        }
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(found, missed)
        }
    }

    // MARK: - Folder listing cache (for Phase 3 existence check)

    private let folderCacheLock = NSLock()
    private var folderListingCache: [Int: (timestamp: Date, items: [ItemVO])] = [:]
    private let folderCacheTTL: TimeInterval = 10

    /// Fetches the destination folder's contents so the Phase 3 retry path can
    /// check whether the server already has the record. Results are cached for
    /// 10 s so a burst of retrying ops doesn't fan out into N navigateMin calls.
    ///
    /// Completion contract:
    /// - `nil`  → the `navigateMin` call itself failed (network, server, decode).
    ///           Callers MUST NOT proceed to call `registerRecord` — they don't
    ///           know whether the server has the record. Re-queue instead.
    /// - `[]`   → folder is verified empty.
    /// - `[…]`  → folder contains these items.
    ///
    /// The cache is only populated on a non-nil response.
    func fetchFolderContents(archiveNo: String, folderLinkId: Int, completion: @escaping ([ItemVO]?) -> Void) {
        folderCacheLock.lock()
        if let cached = folderListingCache[folderLinkId],
           Date().timeIntervalSince(cached.timestamp) < folderCacheTTL {
            let items = cached.items
            folderCacheLock.unlock()
            completion(items)
            return
        }
        folderCacheLock.unlock()

        // Two-step chain — same pattern the file browser uses.
        //
        // Step 1 — `navigateMin` returns the folder skeleton + a list of child
        // `folder_linkId`s but the child `uploadFileName` / `size` fields come
        // back as `nil` (it's a minimal endpoint).
        //
        // Step 2 — `getLeanItems` takes those `folder_linkId`s and returns the
        // hydrated records with `uploadFileName` + `size` populated. That's
        // what we need to match against for duplicate detection — the server
        // rewrites `displayName` from EXIF, but `uploadFileName` is preserved
        // verbatim from `RegisterRecordParams.filename`.
        let navigateMinParams: NavigateMinParams = (archiveNo, folderLinkId, nil)
        let navigateMinOp = APIOperation(FilesEndpoint.navigateMin(params: navigateMinParams))
        navigateMinOp.execute(in: APIRequestDispatcher()) { [weak self] result in
            guard let self = self else { completion(nil); return }
            switch result {
            case .json(let response, _):
                guard let model: NavigateMinResponse = JSONHelper.convertToModel(from: response),
                      let folderVO = model.results?.first?.data?.first?.folderVO else {
                    completion(nil)
                    return
                }
                let children = folderVO.childItemVOS ?? []
                let folderLinkIds: [Int] = children.compactMap { $0.folderLinkID }
                if folderLinkIds.isEmpty {
                    // Folder verifiably empty — cache and return without firing step 2.
                    self.folderCacheLock.lock()
                    self.folderListingCache[folderLinkId] = (Date(), [])
                    self.folderCacheLock.unlock()
                    completion([])
                    return
                }

                let leanParams: GetLeanItemsParams = (archiveNo, .nameAscending, folderLinkIds, folderLinkId)
                let leanOp = APIOperation(FilesEndpoint.getLeanItems(params: leanParams))
                leanOp.execute(in: APIRequestDispatcher()) { [weak self] leanResult in
                    guard let self = self else { completion(nil); return }
                    switch leanResult {
                    case .json(let leanResponse, _):
                        guard let leanModel: NavigateMinResponse = JSONHelper.convertToModel(from: leanResponse),
                              let hydrated = leanModel.results?.first?.data?.first?.folderVO?.childItemVOS else {
                            completion(nil)
                            return
                        }
                        self.folderCacheLock.lock()
                        self.folderListingCache[folderLinkId] = (Date(), hydrated)
                        self.folderCacheLock.unlock()
                        completion(hydrated)
                    default:
                        completion(nil)
                    }
                }
            default:
                completion(nil)
            }
        }
    }

    /// Drops the cached listing for a specific folder. Called from
    /// `UploadOperation` right after a successful `registerRecord` so that the
    /// next reader gets a fresh listing rather than a snapshot from before
    /// this file's record was committed.
    func invalidateFolderListingCache(folderLinkId: Int) {
        folderCacheLock.lock()
        folderListingCache.removeValue(forKey: folderLinkId)
        folderCacheLock.unlock()
    }

    private func clearFolderListingCache() {
        folderCacheLock.lock()
        folderListingCache.removeAll()
        folderCacheLock.unlock()
    }
}
