//
//  UploadOperation.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 09.06.2021.
//

import Foundation

enum UploadError: Error {
    case presignedURL
    case s3
    case registerRecord
}

class UploadOperation: BaseOperation {
    
    static let uploadProgressNotification = Notification.Name("UploadOperation.uploadProgressNotification")
    static let uploadFinishedNotification = Notification.Name("UploadOperation.uploadFinishedNotification")
    
    let file: FileInfo
    let handler: ((Error?) -> Void)
    
    var s3Url: String!
    var destinationUrl: String!
    var fields: [String: String]!
    var createdDT: String!
    
    var progress: Double = 0
    var error: UploadError?
    
    var urlSession: URLSession!
    
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
        
        DispatchQueue.main.async {
            let userInfo: [String: Any]?
            if let error = self.error {
                userInfo = ["error": error]
            } else {
                userInfo = nil
            }
            
            NotificationCenter.default.post(name: Self.uploadFinishedNotification, object: self, userInfo: userInfo)
        }
    }
    
    private func getPresignedUrl(success: @escaping (() -> Void)) {
        guard let resources = try? file.url.resourceValues(forKeys:[.fileSizeKey]),
              let fileSize = resources.fileSize else {
            error = UploadError.presignedURL
            handler(UploadError.presignedURL)
            finish()
            return
        }
        
        let mimeType = (file.url.mimeType ?? "application/octet-stream")
        let params: GetPresignedUrlParams = GetPresignedUrlParams(file.folder.folderId, file.folder.folderLinkId, mimeType, file.name, fileSize, nil)
        
        let apiOperation = APIOperation(FilesEndpoint.getPresignedUrl(params: params))
        apiOperation.execute(in: APIRequestDispatcher()) { [self] result in
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
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        let creationDate = resources.creationDate!
        createdDT = dateFormatter.string(from: creationDate)
        
        var uploadRequest = URLRequest(url: URL(string: s3Url)!)
        uploadRequest.timeoutInterval = 86400
        uploadRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "content-type")
        uploadRequest.addValue("\(contentLength)", forHTTPHeaderField: "Content-Length")
        
        let prefixStream = InputStream(data: prefixData)
        let fileStream = InputStream(url: file.url)!
        let postfixStream = InputStream(data: "\r\n--\(boundary)--".data(using: .utf8)!)
        
        uploadRequest.httpBodyStream = SerialInputStream(inputStreams: [prefixStream, fileStream, postfixStream])
        uploadRequest.httpMethod = "POST"

        let uploadTask = urlSession.uploadTask(with: uploadRequest, from: nil) { [self] data, response, error in
            if let response = response as? HTTPURLResponse, response.statusCode >= 200 && response.statusCode < 300 {
                success()
            } else {
                self.error = UploadError.s3
                handler(UploadError.s3)
                finish()
            }
        }
        uploadTask.resume()
    }
    
    private func registerRecord() {
        let params = RegisterRecordParams(file.folder.folderId, file.folder.folderLinkId, file.name, createdDT, s3Url, destinationUrl)
        
        let apiOperation = APIOperation(FilesEndpoint.registerRecord(params: params))
        apiOperation.execute(in: APIRequestDispatcher()) { [self] result in
            switch result {
            case .json(let response, _):
                guard let model: UploadFileMetaResponse = JSONHelper.convertToModel(from: response) else {
                    self.error = UploadError.registerRecord
                    handler(UploadError.registerRecord)
                    finish()
                    return
                }

                if model.isSuccessful == true {
                    handler(nil)
                    finish()
                } else {
                    self.error = UploadError.registerRecord
                    handler(UploadError.registerRecord)
                    finish()
                }
            case .error(_, _):
                self.error = UploadError.registerRecord
                handler(UploadError.registerRecord)
                finish()
            default:
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
