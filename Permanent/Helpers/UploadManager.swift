//
//  UploadManager.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/10/2020.
//

import Foundation
import MobileCoreServices

class UploadManager {
    static let instance = UploadManager()
    
    func getMimeType(forExtension fileExtension: String) -> String? {
        guard
            let extUTI = UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassFilenameExtension,
                fileExtension as CFString,
                nil
            )?.takeUnretainedValue(),
            
            let mimeUTI = UTTypeCopyPreferredTagWithClass(extUTI, kUTTagClassMIMEType)
        else {
            return nil
        }
        
        return mimeUTI.takeUnretainedValue() as String
    }
    
    func createBoundary() -> String {
        var uuid = UUID().uuidString
        uuid = uuid.replacingOccurrences(of: "-", with: "")
        uuid = uuid.map { $0.lowercased() }.joined()

        let boundary = uuid + "\(Int(Date.timeIntervalSinceReferenceDate))"

        return boundary
    }
    
    private func getHttpBody(forParameters parameters: RequestParameters, withBoundary boundary: String) -> Data {
        var body = Data()

        for (key, value) in parameters {
            guard let value = value else {
                continue
            }
            
            let values = ["--\(boundary)\r\n",
                          "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n",
                          "\(value)\r\n"]
            
            _ = body.append(values: values)
        }

        return body
    }
    
    private func add(file: FileInfo, toBody body: inout Data, withBoundary boundary: String) {
        var status = true
        
        guard
            let content = file.fileContents,
            let mimeType = file.mimeType
        else {
            return
        }

        status = false
        var data = Data()



        let formattedFileInfoPrefix = ["--\(boundary)\r\n",
                                       "Content-Disposition: form-data; name=\"Content-Type\"\r\n\r\n",
                                       mimeType,
                                       "\r\n"]

        let formattedFileInfo = ["--\(boundary)\r\n",
                                 "Content-Disposition: form-data; name=\"file\"; filename=\"\(file.name)\"\r\n",
                                 "Content-Type: \(mimeType)\r\n\r\n"]

        if data.append(values: formattedFileInfoPrefix) {
            if data.append(values: formattedFileInfo) {
                if data.append(values: [content]) {
                    if data.append(values: ["\r\n"]) {
                        status = true
                    }
                }
            }
        }

        if status {
            body.append(data)
        }
    }
    
    private func close(body: inout Data, usingBoundary boundary: String) {
        _ = body.append(values: ["--\(boundary)--"])
        print(body)
    }
    
    func getBodyData(parameters: RequestParameters, file: FileInfo, boundary: String) -> Data? {
        var body = self.getHttpBody(forParameters: parameters, withBoundary: boundary)
        self.add(file: file, toBody: &body, withBoundary: boundary)
        self.close(body: &body, usingBoundary: boundary)
        
        return body
    }
}
