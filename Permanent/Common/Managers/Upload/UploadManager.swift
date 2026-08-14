//
//  UploadManager.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/10/2020.
//

import Foundation
import Network
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
    
    // registerRecord timings driving the dynamic concurrency throttle: it ramps up under 3 s and
    // scales back over 6 s, so a slow server settles at 3-5 rather than the cap of 10.
    private var recentRegisterTimes: [TimeInterval] = []
    private let minConcurrentUploads = 1
    private let maxConcurrentUploads = 10
    private let defaultConcurrentUploads = 1
    private let optimalRegisterTimeThreshold: TimeInterval = 3
    private let maxRegisterTimesToTrack = 5 // Track the last 5 register times
    
    private let logger = Logger(subsystem: "com.permanent.ios", category: "UploadManager")
    private let flowLogger = Logger(subsystem: "com.permanent.ios", category: "UploadFlow")

    // MARK: - Reachability

    /// Watches the network so the queue parks instead of retrying while offline, where
    /// failures return in microseconds and the failure handler re-queues uncapped.
    private let pathMonitor = NWPathMonitor()
    private let pathMonitorQueue = DispatchQueue(label: "com.permanent.ios.upload.reachability")

    /// Defaults to `true` so a monitor that has not reported yet can never block uploads.
    /// Only a `.unsatisfied` path sets it false.
    private var isNetworkAvailable = true

    /// Coalesces `refreshQueue()` so no caller can spin it. Leading edge — the first call
    /// still runs immediately.
    private var refreshThrottle = RefreshThrottle(minInterval: 1.0)
    private let refreshThrottleLock = NSLock()

    /// True for `URLError`s from connectivity loss or handoff, not server faults. These must not
    /// burn retry attempts, since they recover on their own.
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

        // Main runloop in `.common` explicitly: `scheduledTimer` uses RunLoop.current, so a first
        // access off-main would schedule on a runloop that never runs. `.common` survives scrolling.
        let refreshTimer = Timer(timeInterval: 30, target: self, selector: #selector(refreshQueue), userInfo: nil, repeats: true)
        RunLoop.main.add(refreshTimer, forMode: .common)
        timer = refreshTimer

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

        startReachabilityMonitoring()

        logger.info("🔼 UploadManager initialized with \(self.uploadQueue.maxConcurrentOperationCount, privacy: .public) concurrent uploads")
    }

    /// Suspends the queue with no route, so operations cannot start and fail instantly.
    /// Resumes via `refreshQueue()`, which also knows about the failed-auth suspend.
    private func startReachabilityMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let available = path.status == .satisfied
            DispatchQueue.main.async {
                guard available != self.isNetworkAvailable else { return }
                self.isNetworkAvailable = available

                if available {
                    self.flowLogger.info("🔼 [NETWORK] Route available — resuming upload queue")
                    self.refreshQueue()
                } else {
                    self.flowLogger.info("🔼 [NETWORK] No route — suspending upload queue; \(self.uploadQueue.operationCount, privacy: .public) operation(s) parked")
                    self.uploadQueue.isSuspended = true
                }
            }
        }
        pathMonitor.start(queue: pathMonitorQueue)
    }

    @objc private func appDidEnterBackground() {
        // Throttled because `beginBackgroundTask` runtime is limited: 3 keeps a reasonable pace
        // without spending the budget on parallel Phase 1/3 API calls.
        uploadQueue.maxConcurrentOperationCount = 3
        logger.info("🔼 App entered background — limiting to 3 concurrent uploads")

        // Ask iOS to wake us so the queue keeps draining after the foreground budget expires.
        // Host app only: BGTaskScheduler is unavailable in app extensions.
        #if !APP_EXTENSION
        BackgroundUploadDrainTask.schedule()
        #endif
    }

    /// True while an operation is in-flight or a file remains in the persisted queue. Drives
    /// whether a BGProcessingTask wake request stays pending.
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
        pathMonitor.cancel()
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
        guard let accountId: Int = PermSession.currentSession?.account?.accountID else {
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
                    // Light UI work on main: stamp the queue owner and start the Live Activity, so the user
                    // gets visible confirmation right away.
                    DispatchQueue.main.async {
                        UserDefaults.standard.set(accountId, forKey: Constants.Keys.StorageKeys.uploadQueueOwnerAccountIdKey)

                        let archiveNo = PermSession.currentSession?.selectedArchive?.archiveNbr ?? ""
                        let destination = files.first?.folder
                        UploadLiveActivityManager.shared.startActivity(
                            totalFiles: files.count,
                            firstFileName: files.first?.name ?? "",
                            archiveNo: archiveNo,
                            folderLinkId: destination?.folderLinkId ?? 0,
                            folderName: destination?.name ?? "",
                            folderItemCount: destination?.itemCount,
                            folderIsShared: destination?.isShared
                        )
                    }

                    // File-system prep off-main so the spinner keeps animating. No `uploadFilesKey` access here:
                    // UserDefaults is main-only, which serializes against the 30 s timer and avoids a lost update.
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
    
    /// File-system prep only: writes bytes to disk and moves tmp files to durable storage. Does not
    /// touch `uploadFilesKey` — the caller persists, on main, to avoid racing the 30 s timer.
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
    
    /// Throttled entry point. The work itself is `performRefreshQueue()`; this only decides
    /// whether to run it now, once more shortly, or not at all. See `RefreshThrottle`.
    @objc func refreshQueue() {
        refreshThrottleLock.lock()
        let decision = refreshThrottle.request(now: ProcessInfo.processInfo.systemUptime)
        refreshThrottleLock.unlock()

        switch decision {
        case .runNow:
            performRefreshQueue()
        case .alreadyScheduled:
            break
        case .schedule(let delay):
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                self.refreshThrottleLock.lock()
                self.refreshThrottle.pendingRunFired(now: ProcessInfo.processInfo.systemUptime)
                self.refreshThrottleLock.unlock()
                self.performRefreshQueue()
            }
        }
    }

    private func performRefreshQueue() {
        // Network-aware on purpose: without it, the 30 s timer and every foreground would
        // undo the offline suspend.
        if uploadQueue.isSuspended, PermSession.currentSession != nil, isNetworkAvailable {
            logger.info("🔼 Session restored — resuming upload queue")
            uploadQueue.isSuspended = false
        }

        // Wipe the queue when a different account is logged in than the one that owned it: the
        // folderLinkId still belongs to the old account, so the files would land in the wrong archive.
        if let currentAccountId = PermSession.currentSession?.account?.accountID {
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
            // Cross-process read on the calling thread on purpose: it must complete before the enqueue
            // below. Small metadata decode, and usually an absent file with no contention.
            let extensionUploads = try ExtensionUploadManager.shared.savedFiles()
            let selectedArchiveUploads = extensionUploads.filter({ $0.archiveId == selectedArchive?.archiveID })
            
            if selectedArchiveUploads.isEmpty == false {
                logger.info("🔼 Found \(selectedArchiveUploads.count, privacy: .public) files from extension to upload")

                // Clear the App-Group store only after `upload(files:)` has durably persisted the queue, which
                // it does asynchronously. On failure the files stay put and re-upload next launch.
                upload(files: selectedArchiveUploads) { [weak self] success in
                    guard success else { return }
                    // Cross-process clear off-main: this completion arrives on main and the write barrier can block
                    // on the extension's coordination. No ordering dependency — a crash just re-enqueues and dedupes.
                    DispatchQueue.global(qos: .utility).async {
                        do {
                            try ExtensionUploadManager.shared.clearSavedFiles(selectedArchiveUploads)
                        } catch {
                            self?.logger.error("🔼 Failed to clear extension files after enqueue: \(error.localizedDescription, privacy: .public)")
                        }
                    }
                }
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
                    // Notify the Live Activity that these files were silently dropped so
                    // its totalFiles counter doesn't wait forever on phantoms.
                    for _ in removedIds {
                        UploadLiveActivityManager.shared.fileCancelled()
                    }
                }
                if urlsUpdated {
                    try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                }
            }

            // Duplicate prevention for the case where registerRecord succeeded but the app was force-quit
            // before the cleanup removed the file from the persisted queue.
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
                    // These completed elsewhere, so the counter never saw them. `fileCancelled` decrements
                    // totalFiles so the Live Activity isn't left waiting.
                    for _ in duplicateIds {
                        UploadLiveActivityManager.shared.fileCancelled()
                    }
                }
            }
            
            // Clear the completed and in-flight sets and the folder cache once nothing remains, or stale
            // Phase 3 markers trigger needless navigateMin lookups next batch.
            if savedFiles?.isEmpty != false {
                Self.clearCompletedFileIds()
                Self.clearPhase3InFlightIds()
                self.clearFolderListingCache()
            }
            
            // INVARIANT: exactly one live UploadOperation per `file.id`, which is what leaves the unlocked
            // duplicate-prevention checks in `UploadOperation` no concurrent writer for a given id.
            let uploadNames = uploadQueue.operations.filter { !$0.isFinished }.compactMap(\.name)
            let drainingBackgroundFileIds = Set(BackgroundUploadMetadata.loadAll().map(\.fileInfoId))
            for file in savedFiles ?? [] where uploadNames.contains(file.id) == false && !drainingBackgroundFileIds.contains(file.id) {
                let uploadOperation = UploadOperation(file: file) { error in
                    DispatchQueue.main.async {
                        var savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                        savedFiles?.removeAll(where: { $0.id == file.id })

                        if (error as? UploadError) == .cancelled {
                            // A user cancel already removed the file and updated the Live Activity, so skip the completed
                            // accounting or it double-counts. Still fall through to didUploadFile so the UI refreshes.
                        } else if error == nil {
                            FileHelper().deleteFile(at: file.url)

                            try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                            UploadLiveActivityManager.shared.fileCompleted(success: true)

                            // Keep a wake request pending while work remains; pull it once empty.
                            // Host-app only — BGTaskScheduler is unavailable in app extensions.
                            #if !APP_EXTENSION
                            if self.hasPendingWork {
                                BackgroundUploadDrainTask.schedule()
                            } else {
                                BackgroundUploadDrainTask.cancel()
                            }
                            #endif
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

                            // Network errors don't count toward the retry cap, since they recover when connectivity does.
                            // Longer backoff because a Wi-Fi/cellular handoff can take 5-30s to settle.
                            if isTransientNetworkError {
                                self.flowLogger.error("🔼 [HANDLER] NETWORK file=\(file.name, privacy: .public) id=\(file.id, privacy: .public) error=\(error?.localizedDescription ?? "unknown", privacy: .public) — re-queuing without counting retry")
                                if var savedFiles = savedFiles {
                                    savedFiles.append(file)
                                    try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                                } else {
                                    try? PreferencesManager.shared.setCustomObject([file], forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                                }
                                // Only re-queue with a route: Phase 1/3 has no `waitsForConnectivity` and transient errors
                                // bypass the retry cap, so offline this spins. The file is already persisted above.
                                if self.isNetworkAvailable {
                                    self.refreshQueue()
                                } else {
                                    self.uploadQueue.isSuspended = true
                                    self.flowLogger.info("🔼 [HANDLER] No route — parking \(file.name, privacy: .public) until connectivity returns instead of re-queuing")
                                }
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
                
                // Only start an activity when re-queuing after relaunch, where none exists yet. Calling
                // startActivity again over a live one double-counts.
                if !UploadLiveActivityManager.shared.isActive {
                    let reQueuedOps = uploadQueue.operations
                        .compactMap { $0 as? UploadOperation }
                        .filter { !$0.isFinished && !$0.isCancelled }
                    if !reQueuedOps.isEmpty {
                        let archiveNo = PermSession.currentSession?.selectedArchive?.archiveNbr ?? ""
                        // Folder detail rides on the persisted queue, so a re-queue
                        // after relaunch still fills the card.
                        let destination = reQueuedOps.first?.file.folder
                        UploadLiveActivityManager.shared.startActivity(
                            totalFiles: reQueuedOps.count,
                            firstFileName: reQueuedOps.first?.file.name ?? "",
                            archiveNo: archiveNo,
                            folderLinkId: destination?.folderLinkId ?? 0,
                            folderName: destination?.name ?? "",
                            folderItemCount: destination?.itemCount,
                            folderIsShared: destination?.isShared
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

        // Read the persisted queue before clearing it, to delete the backing files. `uploadQueue`
        // is only a subset — anything queued without an operation would leak on disk forever.
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

    /// Serializes read-modify-write on the completed and in-flight marker sets, which are mutated
    /// from both operation threads and main-dispatched completions. Without it, updates are lost.
    private static let markerLock = NSLock()

    /// Marks a file as completed immediately when registerRecord succeeds.
    /// Uses UserDefaults.synchronize() so the write survives a force-quit.
    static func markFileAsCompleted(fileId: String) {
        markerLock.lock()
        defer { markerLock.unlock() }
        let defaults = UserDefaults.standard
        var completedIds = defaults.stringArray(forKey: Constants.Keys.StorageKeys.completedUploadFileIdsKey) ?? []
        guard !completedIds.contains(fileId) else { return }
        completedIds.append(fileId)
        defaults.set(completedIds, forKey: Constants.Keys.StorageKeys.completedUploadFileIdsKey)
        defaults.synchronize()
    }

    /// True once `fileId` has had a successful registerRecord. Checked at the start of Phase 3 so a
    /// re-queued operation cannot create a second archive record for a finished file.
    static func isFileAlreadyCompleted(fileId: String) -> Bool {
        let completedIds = UserDefaults.standard.stringArray(forKey: Constants.Keys.StorageKeys.completedUploadFileIdsKey) ?? []
        return completedIds.contains(fileId)
    }
    
    /// Removes a file ID from the completed set (called during cleanup).
    private static func removeCompletedFileId(_ fileId: String) {
        markerLock.lock()
        defer { markerLock.unlock() }
        let defaults = UserDefaults.standard
        var completedIds = defaults.stringArray(forKey: Constants.Keys.StorageKeys.completedUploadFileIdsKey) ?? []
        completedIds.removeAll(where: { $0 == fileId })
        defaults.set(completedIds, forKey: Constants.Keys.StorageKeys.completedUploadFileIdsKey)
        defaults.synchronize()
    }
    
    /// Clears the entire completed set (called when the persisted queue is empty).
    private static func clearCompletedFileIds() {
        // Take markerLock like every other mutator so a clear can't interleave a concurrent
        // markFileAsCompleted's read→write and resurrect or wipe an id.
        markerLock.lock()
        defer { markerLock.unlock() }
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Constants.Keys.StorageKeys.completedUploadFileIdsKey)
        defaults.synchronize()
    }

    // MARK: - Phase 3 in-flight tracking
    // Closes the "server completed registerRecord but the client lost the response" duplicate window:
    // marked before the call, cleared only on a 200, then reconciled by the retry and batch verifier.

    /// Persisted under `inflightPhase3FileIdsKey`, carrying enough metadata for the verifier to find
    /// the record after `FileInfo` is gone. `fileSize` is the match key; `createdDT` is not exact.
    struct Phase3InFlightEntry: Codable {
        let fileId: String
        let fileName: String
        let createdDT: String
        let fileSize: Int64
        let folderLinkId: Int
        let archiveNo: String
        /// Stela numeric folder id for the V2 dedupe listing. Optional for Codable back-compat: an
        /// older entry decodes nil and the verifier falls back to V1.
        let folderId: Int?
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
        markerLock.lock()
        defer { markerLock.unlock() }
        var entries = phase3InFlightEntries()
        guard !entries.contains(where: { $0.fileId == entry.fileId }) else { return }
        entries.append(entry)
        writePhase3InFlightEntries(entries)
    }

    static func wasPhase3Attempted(fileId: String) -> Bool {
        return phase3InFlightEntries().contains(where: { $0.fileId == fileId })
    }

    static func removePhase3InFlight(fileId: String) {
        markerLock.lock()
        defer { markerLock.unlock() }
        var entries = phase3InFlightEntries()
        entries.removeAll { $0.fileId == fileId }
        writePhase3InFlightEntries(entries)
    }

    private static func clearPhase3InFlightIds() {
        // markerLock like every other mutator (see clearCompletedFileIds).
        markerLock.lock()
        defer { markerLock.unlock() }
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Constants.Keys.StorageKeys.inflightPhase3FileIdsKey)
        defaults.synchronize()
    }

    // MARK: - End-of-batch verification

    /// Reconciles each in-flight Phase 3 entry against the destination folder: present → mark
    /// completed, absent → accept the failure, lookup failed → leave for the next pass.
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
            let folderId = groupEntries.first?.folderId ?? -1
            fetchFolderContents(archiveNo: archiveNo, folderLinkId: folderLinkId, folderId: folderId) { [weak self] items in
                guard let self = self else { group.leave(); return }
                guard let items = items else {
                    // navigateMin failed for this folder, so leave the entries alone for the next pass:
                    // don't drop them from the in-flight set and don't adjust counts.
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
                            // Left behind by a successful retry, which already counted it inline. No Live Activity
                            // correction needed — just clean up the marker.
                            self.flowLogger.info("🔼 [VERIFY] FOUND file=\(entry.fileName, privacy: .public) — already counted as success, cleanup only")
                        } else {
                            // File was counted as failed inline but server
                            // actually has it. Correct the Live Activity.
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

    /// The destination folder's contents, so a Phase 3 retry can tell whether the record already
    /// exists. `nil` means the lookup failed — re-queue, never registerRecord. Cached 10 s.
    func fetchFolderContents(archiveNo: String, folderLinkId: Int, folderId: Int, completion: @escaping ([ItemVO]?) -> Void) {
        folderCacheLock.lock()
        if let cached = folderListingCache[folderLinkId],
           Date().timeIntervalSince(cached.timestamp) < folderCacheTTL {
            let items = cached.items
            folderCacheLock.unlock()
            completion(items)
            return
        }
        folderCacheLock.unlock()

        #if !APP_EXTENSION
        // Flag-gated V2 listing, adapted to the same [ItemVO] currency. Any V2 failure falls back to V1,
        // since `[]` would green-light a duplicate; own-archive only, as the bearer-only read 401s foreign.
        let currentArchiveNbr = PermSession.currentSession?.selectedArchive?.archiveNbr
        if FeatureFlags.useStelaNavigation, folderId > 0,
           !archiveNo.isEmpty, archiveNo == currentArchiveNbr {
            let op = APIOperation(FolderV2Endpoint.getFolderChildren(folderId: String(folderId), shareToken: "", pageSize: FolderV2Endpoint.maxChildrenPageSize))
            op.execute(in: APIRequestDispatcher()) { [weak self] result in
                guard let self = self else { completion(nil); return }
                switch result {
                case .json(let response, _):
                    // Decode and per-item adaptation over an unbounded page is heavy, and the dispatcher delivers
                    // on main. Hops back to main so the completion queue matches the V1 path.
                    DispatchQueue.global(qos: .userInitiated).async {
                        // `items == nil` on an otherwise-decodable 2xx is a contract failure, not an empty folder —
                        // only a present-but-empty array means verified empty. Anything else falls back to V1.
                        guard let model: FolderChildrenV2Response = JSONHelper.decoding(from: response, with: FolderChildrenV2Response.decoder),
                              let children = model.items else {
                            DispatchQueue.main.async {
                                self.performV1FetchFolderContents(archiveNo: archiveNo, folderLinkId: folderLinkId, completion: completion) // failsafe
                            }
                            return
                        }
                        // Records only — dedupe matches files, never subfolders.
                        let items = children.toMatchableItemVOs()
                        self.folderCacheLock.lock()
                        self.folderListingCache[folderLinkId] = (Date(), items)
                        self.folderCacheLock.unlock()
                        DispatchQueue.main.async { completion(items) }
                    }
                default:
                    self.performV1FetchFolderContents(archiveNo: archiveNo, folderLinkId: folderLinkId, completion: completion) // failsafe
                }
            }
            return
        }
        #endif
        performV1FetchFolderContents(archiveNo: archiveNo, folderLinkId: folderLinkId, completion: completion)
    }

    /// The V1 two-step listing, kept as the automatic failsafe behind V2 and used directly when the
    /// flag is off or from the ShareExtension. Same completion contract as the caller.
    private func performV1FetchFolderContents(archiveNo: String, folderLinkId: Int, completion: @escaping ([ItemVO]?) -> Void) {
        // `navigateMin` returns child linkIds with nil names and sizes, so `getLeanItems` hydrates them.
        // Dedupe matches `uploadFileName`, which survives verbatim; the server rewrites displayName.
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

    /// Drops one folder's cached listing, right after a successful `registerRecord`, so the next
    /// reader sees the new record rather than a pre-commit snapshot.
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
