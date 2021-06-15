//
//  UploadOperation.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 09.06.2021.
//

import Foundation

struct UploadStreams {
    let input: InputStream
    let output: OutputStream
}

class UploadOperation: BaseOperation {
    
    static let uploadProgressNotification = Notification.Name("UploadOperation.uploadProgressNotification")
    static let uploadFinishedNotification = Notification.Name("UploadOperation.uploadFinishedNotification")
    
    let file: FileInfo
    let csrf: String
    let handler: ((Error?) -> Void)
    
    var s3Url: String!
    var destinationUrl: String!
    var fields: [String: String]!
    
    var urlSession: URLSession!
    
    lazy var prefixData: Data = {
        return getHttpBody()
    }()
    
    lazy var boundStreams: UploadStreams = {
        var inputOrNil: InputStream? = nil
        var outputOrNil: OutputStream? = nil
        Stream.getBoundStreams(withBufferSize: 16384,
                               inputStream: &inputOrNil,
                               outputStream: &outputOrNil)
        guard let input = inputOrNil, let output = outputOrNil else {
            fatalError("On return of `getBoundStreams`, both `inputStream` and `outputStream` will contain non-nil streams.")
        }
        
        // configure and open output stream
        output.delegate = self
        output.schedule(in: .current, forMode: .default)
        output.open()
        return UploadStreams(input: input, output: output)
    }()
    var fileInputStream: InputStream!
    
    lazy var boundary: String = {
        var uuid = UUID().uuidString
        uuid = uuid.replacingOccurrences(of: "-", with: "")
        uuid = uuid.map { $0.lowercased() }.joined()

        let boundary = uuid + "\(Int(Date.timeIntervalSinceReferenceDate))"

        return boundary
    }()
    
    var didAppendPrefix = false
    var isEOF = false
    
    init(file:FileInfo, csrf: String, handler: @escaping ((Error?) -> Void)) {
        self.file = file
        self.csrf = csrf
        self.handler = handler
    }
    
    override func start() {
        if isCancelled {
            finish()
            return
        }
        
        fileInputStream = InputStream(url: file.url)
        fileInputStream.open()
        
        urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)

        print("UploadOperation: getting presigned url")
        getPresignedUrl { [self] in
            print("UploadOperation: starting S3 upload")
            uploadFileDataToS3 { [self] in
                print("UploadOperation: registering record")
                registerRecord()
            }
        }
        
        super.start()
    }
    
    override func finish() {
        print("finishing")
        file.fileContents = nil
        
        fileInputStream.close()
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.uploadFinishedNotification, object: self)
        }
        
        super.finish()
    }
    
    private func getPresignedUrl(success: @escaping (() -> Void)) {
        guard let resources = try? file.url.resourceValues(forKeys:[.fileSizeKey]),
              let fileSize = resources.fileSize else {
            handler(NSError())
            finish()
            return
        }
        print("Upload Manager: fileSize: \(fileSize)")
        
        let params: GetPresignedUrlParams = GetPresignedUrlParams(file.folder.folderId, file.folder.folderLinkId, file.mimeType, file.name, fileSize, nil, csrf)
        
        let apiOperation = APIOperation(FilesEndpoint.getPresignedUrl(params: params))
        apiOperation.execute(in: APIRequestDispatcher()) { [self] result in
            switch result {
            case .json(let response, _):
                guard let model: GetPresignedUrlResponse = JSONHelper.convertToModel(from: response) else {
                    handler(NSError())
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
                    handler(NSError())
                    finish()
                }
            case .error(let error, _):
                handler(NSError())
                finish()
            default:
                finish()
                break
            }
        }
    }
    
    private func uploadFileDataToS3(success: @escaping (() -> Void)) {
        var contentLength = prefixData.count
        let resources = try! file.url.resourceValues(forKeys:[.fileSizeKey])
        let fileSize = resources.fileSize!
        contentLength += fileSize
        contentLength += "\r\n--\(boundary)--".data(using: .utf8)!.count
        
        var uploadRequest = URLRequest(url: URL(string: s3Url)!)
        uploadRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "content-type")
        uploadRequest.httpBodyStream = boundStreams.input
        uploadRequest.httpMethod = "POST"
        uploadRequest.addValue("\(contentLength)", forHTTPHeaderField: "Content-Length")
        
        let uploadTask = urlSession.dataTask(with: uploadRequest) { [self] data, response, error in
            if let response = response as? HTTPURLResponse, response.statusCode >= 200 && response.statusCode < 300 {
                success()
            } else {
                handler(NSError())
                finish()
            }
        }
        uploadTask.resume()
    }
    
    private func registerRecord() {
        let params = RegisterRecordParams(file.folder.folderId, file.folder.folderLinkId, file.name, nil, self.csrf, s3Url, destinationUrl)
        
        let apiOperation = APIOperation(FilesEndpoint.registerRecord(params: params))
        apiOperation.execute(in: APIRequestDispatcher()) { [self] result in
            switch result {
            case .json(let response, _):
                guard let model: UploadFileMetaResponse = JSONHelper.convertToModel(from: response) else {
                    handler(NSError())
                    finish()
                    return
                }

                if model.isSuccessful == true {
                    handler(nil)
                    finish()
                } else {
                    handler(NSError())
                    finish()
                }
            case .error(let error, _):
                handler(NSError())
                finish()
            default:
                finish()
                break
            }
        }
    }
    
}

extension UploadOperation: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard aStream == boundStreams.output else {
            return
        }
        
        if eventCode.contains(.hasSpaceAvailable) {
            print("has space")
            if isEOF {
                print("is eof")
                boundStreams.output.close()
            } else if !didAppendPrefix {
                print("Upload Manager: Adding prefix")
                let httpBodyData = prefixData
                httpBodyData.withUnsafeBytes { buffer in
                    boundStreams.output.write(buffer, maxLength: httpBodyData.count)
                }
                
                didAppendPrefix = true
            } else {
                print("Upload Manager: reading file")
                let bufferSize = 16384
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                defer {
                    buffer.deallocate()
                }
                if fileInputStream.hasBytesAvailable {
                    let read = fileInputStream.read(buffer, maxLength: bufferSize)
                    if read < 0 {
                        print("stream error")
                        //Stream error occured
                        boundStreams.input.close()
                        boundStreams.output.close()
                        handler(NSError())
                        finish()
                        
                        return
                    } else if read == 0 {
                        //EOF
                        print("stream eof")
                        let data = "\r\n--\(boundary)--".data(using: .utf8)!
                        data.withUnsafeBytes({ buffer in
                            boundStreams.output.write(buffer, maxLength: data.count)
                        })
                        
                        isEOF = true
                        
                        return
                    }
                    boundStreams.output.write(buffer, maxLength: bufferSize)
                }
            }
        }
        
        if eventCode.contains(.errorOccurred) {
            print("Upload Manager: error in stream")
            boundStreams.input.close()
            boundStreams.output.close()
            handler(NSError())
            finish()
        }
    }
}

// MARK: - Upload request body methods
extension UploadOperation {
    private func getHttpBody() -> Data {
        var body = Data()

        for (key, value) in fields {
            body.append(contentsOf: "--\(boundary)\r\n".utf8)
            body.append(contentsOf: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".utf8)
            body.append(contentsOf: "\(value)\r\n".utf8)
        }
        
        body.append(contentsOf: "--\(boundary)\r\n".utf8)
        body.append(contentsOf: "Content-Disposition: form-data; name=\"Content-Type\"\r\n\r\n".utf8)
        body.append(contentsOf: file.url.mimeType!.utf8)
        body.append(contentsOf: "\r\n".utf8)

        body.append(contentsOf: "--\(boundary)\r\n".utf8)
        body.append(contentsOf: "Content-Disposition: form-data; name=\"file\"; filename=\"\(file.name)\"\r\n".utf8)
        body.append(contentsOf: "Content-Type: \(file.url.mimeType!)\r\n\r\n".utf8)

        return body
    }
}

extension UploadOperation: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        
        DispatchQueue.main.async {
            let userInfo: [String : Any] = ["fileInfoId": self.file.id, "progress": progress]
            NotificationCenter.default.post(name: Self.uploadProgressNotification, object: self, userInfo: userInfo)
        }
        print("post progress")
    }
}
