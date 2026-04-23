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
}

class UploadOperation: BaseOperation, @unchecked Sendable {
    static let uploadProgressNotification = Notification.Name("UploadOperation.uploadProgressNotification")
    static let uploadFinishedNotification = Notification.Name("UploadOperation.uploadFinishedNotification")
    static let registerRecordTimingNotification = Notification.Name("UploadOperation.registerRecordTimingNotification")
    
    // Logger for upload operations
    private let logger = Logger(subsystem: "com.permanent.ios", category: "UploadOperation")
    
    let file: FileInfo
    let handler: ((Error?) -> Void)
    
    var s3Url: String!
    var destinationUrl: String!
    var fields: [String: String]!
    var createdDT: String!
    
    var progress: Double = 0
    var error: UploadError?
    
    var uploadTask: URLSessionUploadTask?
    
    var urlSession: URLSession!
    
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
    
    init(file:FileInfo, handler: @escaping ((Error?) -> Void)) {
        self.file = file
        self.handler = handler
    }
    
    override func start() {
        if isCancelled {
            finish()
            return
        }
        
        // Request background execution time so uploads can continue briefly when app is backgrounded
        if let app = extensionSafeApplication() {
            backgroundTaskId = app.beginBackgroundTask(withName: "UploadFile-\(file.id)") { [weak self] in
                guard let self = self else { return }
                self.logger.warning("Background task expired for file: \(self.file.name, privacy: .public)")
                // Cancel the in-flight upload since we're about to lose execution time
                self.uploadTask?.cancel()
                self.error = UploadError.s3
                extensionSafeApplication()?.endBackgroundTask(self.backgroundTaskId)
                self.backgroundTaskId = .invalid
            }
        }
        
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        
        getPresignedUrl { [self] in
            uploadFileDataToS3 { [self] in
                registerRecord()
            }
        }
        
        super.start()
    }
    
    override func finish() {
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
        uploadTask?.cancel()
        
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
        guard let resources = try? file.url.resourceValues(forKeys:[.fileSizeKey]),
              let fileSize = resources.fileSize else {
            logger.error("Failed to get file size for: \(self.file.name, privacy: .public)")
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
                } else {
                    error = UploadError.presignedURL
                    handler(UploadError.presignedURL)
                    finish()
                }
            case .error(_, _):
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
        var contentLength = prefixData.count
        let resources = try! file.url.resourceValues(forKeys:[.fileSizeKey, .creationDateKey])
        let fileSize = resources.fileSize!
        contentLength += fileSize
        contentLength += "\r\n--\(boundary)--".data(using: .utf8)!.count
        
        logger.debug("Preparing to upload file to S3: \(self.file.name, privacy: .public), size: \(fileSize, privacy: .public) bytes")
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        let creationDate = resources.creationDate!
        createdDT = dateFormatter.string(from: creationDate)
        
        var uploadRequest = URLRequest(url: URL(string: s3Url)!)
        uploadRequest.timeoutInterval = 86400 // 24 hours timeout for large files
        uploadRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "content-type")
        uploadRequest.addValue("\(contentLength)", forHTTPHeaderField: "Content-Length")
        uploadRequest.httpMethod = "POST"

        let prefixStream = InputStream(data: prefixData)
        let fileStream = InputStream(url: file.url)!
        let postfixStream = InputStream(data: "\r\n--\(boundary)--".data(using: .utf8)!)
        
        let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let outputStream = OutputStream(url: tempFileURL, append: false)!
        outputStream.open()
        
        // Write prefix data (multipart form fields + file header)
        var buffer = [UInt8](repeating: 0, count: 1024 * 64) // 64KB buffer for faster writes
        prefixStream.open()
        while prefixStream.hasBytesAvailable {
            let bytesRead = prefixStream.read(&buffer, maxLength: buffer.count)
            if bytesRead > 0 {
                outputStream.write(buffer, maxLength: bytesRead)
            } else {
                break
            }
        }
        prefixStream.close()
        
        // Write file data
        fileStream.open()
        while fileStream.hasBytesAvailable {
            let bytesRead = fileStream.read(&buffer, maxLength: buffer.count)
            if bytesRead > 0 {
                outputStream.write(buffer, maxLength: bytesRead)
            } else {
                break
            }
        }
        fileStream.close()
        
        // Write postfix data (closing boundary)
        postfixStream.open()
        while postfixStream.hasBytesAvailable {
            let bytesRead = postfixStream.read(&buffer, maxLength: buffer.count)
            if bytesRead > 0 {
                outputStream.write(buffer, maxLength: bytesRead)
            } else {
                break
            }
        }
        postfixStream.close()
        
        outputStream.close()

        uploadTask = urlSession.uploadTask(with: uploadRequest, fromFile: tempFileURL, completionHandler: { [self] data, response, error in
            guard isCancelled == false else { return }
            
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempFileURL)
            
            if let error = error {
                logger.error("S3 upload error: \(error.localizedDescription, privacy: .public) for file: \(self.file.name, privacy: .public)")
                self.error = UploadError.s3
                handler(UploadError.s3)
                finish()
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 200, httpResponse.statusCode < 300 {
                logger.info("Successfully uploaded file to S3: \(self.file.name, privacy: .public)")
                success()
            } else {
                logger.error("S3 upload returned unexpected status for file: \(self.file.name, privacy: .public)")
                self.error = UploadError.s3
                handler(UploadError.s3)
                finish()
            }
        })
        uploadTask?.resume()

        logger.debug("Started S3 upload task for file: \(self.file.name, privacy: .public)")
    }
    
    private func registerRecord() {
        let registerStartTime = Date()
        let params = RegisterRecordParams(file.folder.folderId, file.folder.folderLinkId, file.name, createdDT, s3Url, destinationUrl)
        
        logger.debug("Starting registerRecord for file: \(self.file.name, privacy: .public)")
        
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
                    logger.info("Successfully registered file: \(self.file.name, privacy: .public)")
                    uploadedFile = model.results?.first?.data?.first?.recordVO
                    
                    // Mark as completed IMMEDIATELY (before the main-queue hop in the handler)
                    // so a force-quit between here and queue cleanup won't cause a duplicate.
                    UploadManager.markFileAsCompleted(fileId: self.file.id)
                    
                    handler(nil)
                    finish()
                } else {
                    logger.error("Server returned unsuccessful response for registerRecord: \(self.file.name, privacy: .public)")
                    self.error = UploadError.registerRecord
                    handler(UploadError.registerRecord)
                    finish()
                }
            case .error(let error, _):
                logger.error("Error during registerRecord: \(error.debugDescription, privacy: .public) for file: \(self.file.name, privacy: .public)")
                self.error = UploadError.registerRecord
                handler(UploadError.registerRecord)
                finish()
            default:
                logger.error("Unexpected result type from registerRecord for file: \(self.file.name, privacy: .public)")
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

// MARK: - URLSessionTaskDelegate
extension UploadOperation: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        
        DispatchQueue.main.async {
            let userInfo: [String: Any] = ["fileInfoId": self.file.id, "progress": self.progress]
            NotificationCenter.default.post(name: Self.uploadProgressNotification, object: self, userInfo: userInfo)
            
            let queueIndex = UploadManager.shared.uploadQueue.operations
                .compactMap { $0 as? UploadOperation }
                .firstIndex(where: { $0.file.id == self.file.id })
            let fileIndex = (queueIndex ?? 0) + 1
            
            UploadLiveActivityManager.shared.updateProgress(
                fileInfoId: self.file.id,
                fileName: self.file.name,
                fileIndex: fileIndex,
                fileProgress: self.progress
            )
        }
    }
}
