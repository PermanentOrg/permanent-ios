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
    /// Populated in Phase 2 (`uploadFileDataToS3`) once the byte count is
    /// known. Used by Phase 3 / Guard B as the duplicate-prevention match key
    /// (matched against `ItemVO.size` returned by `navigateMin`). Size is
    /// numeric and round-trips through the server exactly, unlike `createdDT`
    /// which is reformatted server-side.
    var phase2FileSize: Int64?
    
    var progress: Double = 0
    var error: Error?

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
                self.logger.warning("🔼 Background task expired for file: \(self.file.name, privacy: .public)")
                extensionSafeApplication()?.endBackgroundTask(self.backgroundTaskId)
                self.backgroundTaskId = .invalid
            }
        }

        operationStartTime = Date()

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

        if foregroundUploadTask == nil, let op = getPresignedURLOperation {
            logger.info("🔼 Cancelling stale presignedUrl after foreground resume for: \(self.file.name, privacy: .public)")
            op.cancel()
        } else if let task = foregroundUploadTask {
            logger.info("🔼 Cancelling stale foreground upload after foreground resume for: \(self.file.name, privacy: .public)")
            task.cancel()
        } else if let op = registerRecordOperation {
            logger.info("🔼 Cancelling stale registerRecord after foreground resume for: \(self.file.name, privacy: .public)")
            op.cancel()
        }
    }
    
    override func finish() {
        // Single terminal log per file so we can trace the success path too.
        // Failures already log via `[PHASE N FAILED]`; skips via `[PHASE 3 SKIP]`.
        // This line is the silent-success complement, so for a 100-file batch
        // every file has exactly one outcome line in Console.app.
        if error == nil {
            flowLogger.info("🔼 [OK] file=\(self.file.name, privacy: .public) id=\(self.file.id, privacy: .public) t=\(self.elapsed, privacy: .public)s")
        }

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

        guard let resources = try? file.url.resourceValues(forKeys:[.fileSizeKey]),
              let fileSize = resources.fileSize else {
            flowLogger.error("🔼 [PHASE 1 FAILED] t=\(self.elapsed, privacy: .public)s Cannot get file size for: \(self.file.name, privacy: .public)")
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
                    success()
                } else if model.isSuccessful == false, model.results?.first?.data == nil {
                    self.flowLogger.error("🔼 [PHASE 1 AUTH] t=\(self.elapsed, privacy: .public)s session invalid for: \(self.file.name, privacy: .public)")
                    error = UploadError.authenticationRequired
                    handler(UploadError.authenticationRequired)
                    finish()
                } else {
                    self.flowLogger.error("🔼 [PHASE 1 FAILED] t=\(self.elapsed, privacy: .public)s presignedUrl response unsuccessful for: \(self.file.name, privacy: .public)")
                    error = UploadError.presignedURL
                    handler(UploadError.presignedURL)
                    finish()
                }
            case .error(let err, _):
                self.flowLogger.error("🔼 [PHASE 1 FAILED] t=\(self.elapsed, privacy: .public)s presignedUrl network error: \(err?.localizedDescription ?? "unknown", privacy: .public)")
                // Preserve URLError so UploadManager's isTransientNetworkError
                // check fires and retry without burning attempts.
                if let urlError = err as? URLError {
                    self.error = urlError
                    handler(urlError)
                } else {
                    self.error = UploadError.presignedURL
                    handler(UploadError.presignedURL)
                }
                finish()
            default:
                finish()
                break
            }
        }
    }
    
    private func uploadFileDataToS3(success: @escaping (() -> Void)) {
        phaseStartTime = Date()
        var contentLength = prefixData.count

        guard let resources = try? file.url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey]),
              let fileSize = resources.fileSize,
              let creationDate = resources.creationDate else {
            flowLogger.error("🔼 [PHASE 2 FAILED] file=\(self.file.name, privacy: .public) — missing resource values (file may be gone)")
            self.error = UploadError.s3
            handler(UploadError.s3)
            finish()
            return
        }
        // Cache the byte count so Phase 3 can use it as the duplicate-prevention
        // match key (server's ItemVO.size round-trips numerically, unlike
        // createdDT which gets timezone-normalised).
        phase2FileSize = Int64(fileSize)
        contentLength += fileSize

        guard let boundaryClose = "\r\n--\(boundary)--".data(using: .utf8) else {
            flowLogger.error("🔼 [PHASE 2 FAILED] file=\(self.file.name, privacy: .public) — could not encode boundary")
            self.error = UploadError.s3
            handler(UploadError.s3)
            finish()
            return
        }
        contentLength += boundaryClose.count

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        createdDT = dateFormatter.string(from: creationDate)

        guard let uploadURL = URL(string: s3Url) else {
            flowLogger.error("🔼 [PHASE 2 FAILED] file=\(self.file.name, privacy: .public) — invalid s3Url")
            self.error = UploadError.s3
            handler(UploadError.s3)
            finish()
            return
        }
        var uploadRequest = URLRequest(url: uploadURL)
        uploadRequest.timeoutInterval = 86400
        uploadRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "content-type")
        uploadRequest.addValue("\(contentLength)", forHTTPHeaderField: "Content-Length")
        uploadRequest.httpMethod = "POST"

        // Build multipart body into a temp file in the app group container
        // so it survives app termination.
        let tempURL = BackgroundUploadSessionManager.uploadTempDirectory.appendingPathComponent(UUID().uuidString)
        guard let outputStream = OutputStream(url: tempURL, append: false) else {
            flowLogger.error("🔼 [PHASE 2 FAILED] file=\(self.file.name, privacy: .public) — could not open tempfile output stream (disk full?)")
            self.error = UploadError.s3
            handler(UploadError.s3)
            finish()
            return
        }
        outputStream.open()

        var buffer = [UInt8](repeating: 0, count: 1024 * 64)

        let prefixStream = InputStream(data: prefixData)
        prefixStream.open()
        while prefixStream.hasBytesAvailable {
            let bytesRead = prefixStream.read(&buffer, maxLength: buffer.count)
            if bytesRead > 0 { outputStream.write(buffer, maxLength: bytesRead) } else { break }
        }
        prefixStream.close()

        guard let fileStream = InputStream(url: file.url) else {
            outputStream.close()
            try? FileManager.default.removeItem(at: tempURL)
            flowLogger.error("🔼 [PHASE 2 FAILED] file=\(self.file.name, privacy: .public) — could not open input stream for source file")
            self.error = UploadError.s3
            handler(UploadError.s3)
            finish()
            return
        }
        fileStream.open()
        while fileStream.hasBytesAvailable {
            let bytesRead = fileStream.read(&buffer, maxLength: buffer.count)
            if bytesRead > 0 { outputStream.write(buffer, maxLength: bytesRead) } else { break }
        }
        fileStream.close()

        let postfixStream = InputStream(data: boundaryClose)
        postfixStream.open()
        while postfixStream.hasBytesAvailable {
            let bytesRead = postfixStream.read(&buffer, maxLength: buffer.count)
            if bytesRead > 0 { outputStream.write(buffer, maxLength: bytesRead) } else { break }
        }
        postfixStream.close()
        outputStream.close()

        // All uploads run through the foreground URLSession. iOS gives the app
        // ~30s of runtime via beginBackgroundTask after backgrounding; uploads
        // that exceed that pause until the user reopens the app (LA shows the
        // orange "Upload Paused — tap to resume" state).
        foregroundTempFileURL = tempURL
        let task = Self.foregroundSession.uploadTask(with: uploadRequest, fromFile: tempURL) { [weak self] _, response, error in
            guard let self = self, !self.isCancelled else { return }

            // Clean up temp file
            if let tempPath = self.foregroundTempFileURL {
                try? FileManager.default.removeItem(at: tempPath)
            }
            self.foregroundUploadTask = nil

            if let error = error {
                self.flowLogger.error("🔼 [PHASE 2 FAILED] t=\(self.elapsed, privacy: .public)s dur=\(self.phaseDuration, privacy: .public)s error=\(error.localizedDescription, privacy: .public)")
                // Preserve URLError so UploadManager's isTransientNetworkError
                // check fires and the file is re-queued without burning attempts.
                if let urlError = error as? URLError {
                    self.error = urlError
                    self.handler(urlError)
                } else {
                    self.error = UploadError.s3
                    self.handler(UploadError.s3)
                }
                self.finish()
            } else if let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) {
                success()
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                self.flowLogger.error("🔼 [PHASE 2 FAILED] t=\(self.elapsed, privacy: .public)s dur=\(self.phaseDuration, privacy: .public)s status=\(statusCode, privacy: .public)")
                self.error = UploadError.s3
                self.handler(UploadError.s3)
                self.finish()
            }
        }
        foregroundUploadTask = task

        progressObservation = task.progress.observe(\Progress.fractionCompleted) { [weak self] (taskProgress: Progress, _: NSKeyValueObservedChange<Double>) in
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
    }

    private func registerRecord() {
        // Guard A: in-memory dedup. If this operation already finished Phase 3
        // successfully in the current process (re-queued mid-flight), skip the
        // API call entirely.
        if UploadManager.isFileAlreadyCompleted(fileId: file.id) {
            flowLogger.info("🔼 [PHASE 3 SKIP] file=\(self.file.name, privacy: .public) id=\(self.file.id, privacy: .public) already registered — in-memory dedup")
            handler(nil)
            finish()
            return
        }

        // Guard B: if a previous attempt for this file got as far as issuing
        // registerRecord but didn't return success to the client (server may
        // still have created the record while the response was lost in
        // transit — common during Wi-Fi/cellular handoff), list the
        // destination folder and look for a matching record by name +
        // millisecond-precise createdDT. If found, the server already has it
        // and a fresh call would create a duplicate.
        if UploadManager.wasPhase3Attempted(fileId: file.id) {
            let archiveNo = PermSession.currentSession?.selectedArchive?.archiveNbr ?? ""
            UploadManager.shared.fetchFolderContents(archiveNo: archiveNo, folderLinkId: file.folder.folderLinkId) { [self] items in
                guard !isCancelled else { return }

                // Fix 2: if navigateMin itself failed, we have NO idea whether
                // the server already has this record. Falling through to a
                // fresh `registerRecord` is exactly what creates the duplicate
                // we're trying to prevent. Defer instead — re-queue as a
                // transient network error so the next retry can try Guard B
                // again. The retry doesn't count against the 3-attempt cap
                // (it goes through `isTransientNetworkError`).
                guard let items = items else {
                    flowLogger.error("🔼 [PHASE 3 FAILED] file=\(self.file.name, privacy: .public) id=\(self.file.id, privacy: .public) — Guard B navigateMin unreachable, deferring")
                    let urlError = URLError(.networkConnectionLost)
                    self.error = urlError
                    handler(urlError)
                    finish()
                    return
                }

                // Shared matcher: `uploadFileName` exact, with stripped
                // `displayName` as fallback, and `size` as a tiebreaker. See
                // `ItemVOMatching.swift` for the full rationale behind the
                // key choice.
                if items.record(forUploadName: file.name, size: resolvedFileSize()) != nil {
                    flowLogger.info("🔼 [PHASE 3 SKIP] file=\(self.file.name, privacy: .public) id=\(self.file.id, privacy: .public) found in folder — server already has it (folder-existence-check)")
                    UploadManager.markFileAsCompleted(fileId: file.id)
                    UploadManager.removePhase3InFlight(fileId: file.id)
                    handler(nil)
                    finish()
                    return
                }
                doRegisterRecord()
            }
            return
        }

        doRegisterRecord()
    }

    /// Returns the file's byte count for use as the duplicate-prevention match
    /// key. Prefers the Phase-2-cached value (already on disk's perspective when
    /// we built the upload body); falls back to a fresh `resourceValues` read
    /// for any pathological path that skipped Phase 2 (shouldn't happen — we
    /// only reach Phase 3 after Phase 2 success).
    private func resolvedFileSize() -> Int64 {
        if let cached = phase2FileSize { return cached }
        if let fs = (try? file.url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
            return Int64(fs)
        }
        return 0
    }

    private func doRegisterRecord() {
        // Capture retry-or-first-attempt BEFORE marking. After API success the
        // in-flight marker is removed only for first attempts — for retries
        // it must persist so the end-of-batch verifier can confirm there
        // isn't a leftover duplicate from an earlier attempt that the server
        // processed without acknowledging.
        let wasRetry = UploadManager.wasPhase3Attempted(fileId: file.id)

        // Mark in-flight BEFORE the API call so that if the response is lost
        // mid-flight, the next retry takes the folder-existence-check path
        // (Guard B) and the end-of-batch verifier has the metadata it needs
        // to look this record up via navigateMin. Idempotent.
        let archiveNo = PermSession.currentSession?.selectedArchive?.archiveNbr ?? ""
        let fileSizeBytes = resolvedFileSize()
        UploadManager.markPhase3InFlight(entry: UploadManager.Phase3InFlightEntry(
            fileId: file.id,
            fileName: file.name,
            createdDT: createdDT,
            fileSize: fileSizeBytes,
            folderLinkId: file.folder.folderLinkId,
            archiveNo: archiveNo
        ))

        let registerStartTime = Date()
        let params = RegisterRecordParams(file.folder.folderId, file.folder.folderLinkId, file.name, createdDT, s3Url, destinationUrl)

        phaseStartTime = Date()

        let apiOperation = APIOperation(FilesEndpoint.registerRecord(params: params))
        apiOperation.execute(in: APIRequestDispatcher()) { [self] result in
            guard isCancelled == false else { return }

            let registerTime = Date().timeIntervalSince(registerStartTime)

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
                    logger.error("🔼 Failed to convert registerRecord response to model for file: \(self.file.name, privacy: .public)")
                    self.error = UploadError.registerRecord
                    handler(UploadError.registerRecord)
                    finish()
                    return
                }

                if model.isSuccessful == true {
                    uploadedFile = model.results?.first?.data?.first?.recordVO
                    UploadManager.markFileAsCompleted(fileId: self.file.id)
                    if !wasRetry {
                        // First-attempt success — no risk of a prior server
                        // success we missed, so safe to drop the marker.
                        UploadManager.removePhase3InFlight(fileId: self.file.id)
                    }
                    // Invalidate the cached folder listing so the next reader
                    // gets a fresh navigateMin response that includes this
                    // newly-registered record (prevents stale-empty reads
                    // from triggering a duplicate-creating fall-through).
                    UploadManager.shared.invalidateFolderListingCache(folderLinkId: self.file.folder.folderLinkId)
                    handler(nil)
                    finish()
                } else {
                    flowLogger.error("🔼 [PHASE 3 FAILED] t=\(self.elapsed, privacy: .public)s dur=\(self.phaseDuration, privacy: .public)s registerRecord unsuccessful")
                    // Leave in-flight marker in place so the next retry
                    // consults the folder before re-issuing.
                    self.error = UploadError.registerRecord
                    handler(UploadError.registerRecord)
                    finish()
                }
            case .error(let error, _):
                flowLogger.error("🔼 [PHASE 3 FAILED] t=\(self.elapsed, privacy: .public)s dur=\(self.phaseDuration, privacy: .public)s network error: \(error?.localizedDescription ?? "unknown", privacy: .public)")
                // Leave in-flight marker — the lost response is *exactly* the
                // case we want the next retry to catch via Guard B.
                if let urlError = error as? URLError {
                    self.error = urlError
                    handler(urlError)
                } else {
                    self.error = UploadError.registerRecord
                    handler(UploadError.registerRecord)
                }
                finish()
            default:
                flowLogger.error("🔼 [PHASE 3 FAILED] t=\(self.elapsed, privacy: .public)s unexpected result type")
                // Leave in-flight marker.
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

