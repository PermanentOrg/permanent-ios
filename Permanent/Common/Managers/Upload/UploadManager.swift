//
//  UploadManager.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/10/2020.
//

import Foundation
import os.log

class UploadManager {
    static let didRefreshQueueNotification = Notification.Name("UploadManager.didRefreshQueueNotification")
    static let didUploadFileNotification = Notification.Name("UploadManager.didUploadFileNotification")
    static let quotaExceededNotification = Notification.Name("UploadManager.quotaExceededNotification")
    static let didCreateMobileUploadsFolderNotification = Notification.Name("UploadManager.didCreateMobileUploadsFolderNotification")
    
    static let shared: UploadManager = UploadManager()
    
    let uploadQueue: OperationQueue = OperationQueue()
    
    var timer: Timer?
    
    // Track registerRecord timing for dynamic concurrency adjustment
    private var recentRegisterTimes: [TimeInterval] = []
    private let minConcurrentUploads = 1
    private let maxConcurrentUploads = 10
    private let defaultConcurrentUploads = 1
    private let optimalRegisterTimeThreshold: TimeInterval = 10 // 10 seconds is considered optimal for registerRecord
    private let maxRegisterTimesToTrack = 5 // Track the last 5 register times
    
    // Logger for upload concurrency management
    private let logger = Logger(subsystem: "com.permanent.ios", category: "UploadManager")
    
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
        
        logger.info("UploadManager initialized with \(self.uploadQueue.maxConcurrentOperationCount, privacy: .public) concurrent uploads")
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
        
        logger.info("Average registerRecord time: \(averageRegisterTime, privacy: .public) seconds, Concurrent uploads: \(self.uploadQueue.maxConcurrentOperationCount, privacy: .public)")
    }
    
    private func increaseConcurrentUploads() {
        let current = uploadQueue.maxConcurrentOperationCount
        if current < maxConcurrentUploads {
            uploadQueue.maxConcurrentOperationCount = current + 1
            logger.info("Increased concurrent uploads to: \(self.uploadQueue.maxConcurrentOperationCount, privacy: .public)")
        }
    }
    
    private func decreaseConcurrentUploads() {
        let current = uploadQueue.maxConcurrentOperationCount
        if current > minConcurrentUploads {
            uploadQueue.maxConcurrentOperationCount = current - 1
            logger.info("Decreased concurrent uploads to: \(self.uploadQueue.maxConcurrentOperationCount, privacy: .public)")
        }
    }
    
    func upload(files: [FileInfo]) {
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
            logger.error("No active session found")
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
                    self.logger.error("Failed to get user data")
                    return
                }

                if model.results[0].data?[0].accountVO?.spaceLeft ?? 0 > filesSize {
                    DispatchQueue.main.async {
                        let archiveNo = PermSession.currentSession?.selectedArchive?.archiveNbr ?? ""
                        let folderLinkId = files.first?.folder.folderLinkId ?? 0
                        UploadLiveActivityManager.shared.startActivity(
                            totalFiles: files.count,
                            firstFileName: files.first?.name ?? "",
                            archiveNo: archiveNo,
                            folderLinkId: folderLinkId
                        )
                        
                        for file in files {
                            self.upload(file: file)
                        }
                        
                        self.refreshQueue()
                    }
                } else {
                    self.logger.error("Quota exceeded - not enough space left")
                    NotificationCenter.default.post(name: Self.quotaExceededNotification, object: self, userInfo: nil)
                }

                return

            case .error(let error, _):
                self.logger.error("Error getting user data: \(error.debugDescription, privacy: .public)")
                return

            default:
                self.logger.error("Unexpected result type from getUserData")
                break
            }
        }
    }
    
    func upload(file: FileInfo, shouldRefreshQueue: Bool = false) {
        // Save the file data locally, otherwise the fileURL will be invalidated next session
        let fileHelper = FileHelper()
        if let fileContents = file.fileContents {
            file.url = fileHelper.saveFile(fileContents, named: file.id, withExtension: "jpeg", isDownload: false) ?? URL(fileURLWithPath: "")
            file.fileContents = nil
        }
        
        logger.debug("Preparing to upload file: \(file.name, privacy: .public), id: \(file.id, privacy: .public)")
        
        // Save file metadata
        let savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        if var savedFiles = savedFiles {
            if savedFiles.map({ $0.id }).contains(file.id) == false {
                savedFiles.append(file)
                try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
            }
        } else {
            try? PreferencesManager.shared.setCustomObject([file], forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        }
        
        // Start uploading
        if shouldRefreshQueue {
            refreshQueue()
        }
    }
    
    @objc
    func refreshQueue() {
        do {
            let selectedArchive = PermSession.currentSession?.selectedArchive
            let extensionUploads = try ExtensionUploadManager.shared.savedFiles()
            let selectedArchiveUploads = extensionUploads.filter({ $0.archiveId == selectedArchive?.archiveID })
            
            if selectedArchiveUploads.isEmpty == false {
                logger.info("Found \(selectedArchiveUploads.count, privacy: .public) files from extension to upload")
                
                for file in selectedArchiveUploads {
                    logger.info("Extension file: \(file.name, privacy: .public), archive: \(file.archiveId, privacy: .public)")
                }
                
                upload(files: selectedArchiveUploads)
                try ExtensionUploadManager.shared.clearSavedFiles(selectedArchiveUploads)
            } else if !extensionUploads.isEmpty {
                logger.info("Found \(extensionUploads.count, privacy: .public) extension files but none match current archive ID: \(selectedArchive?.archiveID ?? -1, privacy: .public)")
            }
        } catch {
            logger.error("Error refreshing upload queue: \(error.localizedDescription, privacy: .public)")
        }
        
        DispatchQueue.main.async { [self] in
            var didRefresh = false
            
            var savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
            
            // Remove files that were already successfully uploaded (duplicate prevention).
            // This handles the case where registerRecord succeeded but the app was force-quit
            // before the main-queue cleanup could remove the file from the persisted queue.
            let completedIds = UserDefaults.standard.stringArray(forKey: Constants.Keys.StorageKeys.completedUploadFileIdsKey) ?? []
            if !completedIds.isEmpty, let files = savedFiles {
                let duplicateIds = files.filter { completedIds.contains($0.id) }.map(\.id)
                if !duplicateIds.isEmpty {
                    logger.info("Removing \(duplicateIds.count, privacy: .public) already-completed files from persisted queue")
                    for id in duplicateIds {
                        if let url = files.first(where: { $0.id == id })?.url {
                            FileHelper().deleteFile(at: url)
                        }
                        Self.removeCompletedFileId(id)
                    }
                    savedFiles?.removeAll(where: { duplicateIds.contains($0.id) })
                    try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                }
            }
            
            // Clear the completed set when no files remain in the queue
            if savedFiles?.isEmpty != false {
                Self.clearCompletedFileIds()
            }
            
            let uploadNames = uploadQueue.operations.compactMap(\.name)
            for file in savedFiles ?? [] where uploadNames.contains(file.id) == false {
                let uploadOperation = UploadOperation(file: file) { error in
                    DispatchQueue.main.async {
                        var savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                        savedFiles?.removeAll(where: { $0.id == file.id })
                        
                        if error == nil {
                            self.logger.info("Successfully uploaded file: \(file.name, privacy: .public)")
                            FileHelper().deleteFile(at: file.url)
                            
                            try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                            UploadLiveActivityManager.shared.fileCompleted(success: true)
                        } else {
                            self.logger.error("Failed to upload file: \(file.name, privacy: .public), error: \(error?.localizedDescription ?? "unknown", privacy: .public)")
                            file.didFailUpload = true
                            
                            if var savedFiles = savedFiles {
                                savedFiles.append(file)
                                try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                            } else {
                                try? PreferencesManager.shared.setCustomObject([file], forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                            }
                            UploadLiveActivityManager.shared.fileCompleted(success: false)
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
                logger.info("Refreshed upload queue with new files")
                
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
        logger.info("Cancelling upload for file ID: \(fileId, privacy: .public)")
        
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
        logger.info("Cancelling all uploads")
        
        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        Self.clearCompletedFileIds()
        
        let files = uploadQueue.operations.map({ $0 as! UploadOperation }).map(\.file)
        uploadQueue.cancelAllOperations()
        
        files.forEach { file in
            FileHelper().deleteFile(at: file.url)
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
}
