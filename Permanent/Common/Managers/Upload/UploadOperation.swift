//
//  UploadOperation.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 09.06.2021.
//

import Foundation
import os.log

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
    
    var urlSession: URLSession!
    
    var uploadTask: URLSessionUploadTask?
    
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
    
    init(file:FileInfo, handler: @escaping ((Error?) -> Void)) {
        self.file = file
        self.handler = handler
    }
    
    override func start() {
        if isCancelled {
            finish()
            return
        }
        
        urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        
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
        
        // Create a temporary file to hold the complete request body
        let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let outputStream = OutputStream(url: tempFileURL, append: false)!
        outputStream.open()
        
        // Write prefix data
        var buffer = [UInt8](repeating: 0, count: 1024)
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
        
        // Write postfix data
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
        
        // Now use the correct upload method with the temporary file
        uploadTask = urlSession.uploadTask(with: uploadRequest, fromFile: tempFileURL) { [self] data, response, error in
            // Clean up the temporary file
            try? FileManager.default.removeItem(at: tempFileURL)
            
            guard isCancelled == false else { return }
            
            if let error = error {
                logger.error("S3 upload error: \(error.localizedDescription, privacy: .public) for file: \(self.file.name, privacy: .public)")
                self.error = UploadError.s3
                handler(UploadError.s3)
                finish()
                return
            }
            
            if let response = response as? HTTPURLResponse, response.statusCode >= 200 && response.statusCode < 300 {
                logger.info("Successfully uploaded file to S3: \(self.file.name, privacy: .public), status: \(response.statusCode, privacy: .public)")
                success()
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                logger.error("S3 upload failed with status code: \(statusCode, privacy: .public) for file: \(self.file.name, privacy: .public)")
                self.error = UploadError.s3
                handler(UploadError.s3)
                finish()
            }
        }
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

extension UploadOperation: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        
        DispatchQueue.main.async { [self] in
            let userInfo: [String : Any] = ["fileInfoId": file.id, "progress": progress]
            NotificationCenter.default.post(name: Self.uploadProgressNotification, object: self, userInfo: userInfo)
        }
        
        if isCancelled {
            urlSession.invalidateAndCancel()
        }
    }
}
