//
//  UploadManager.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/10/2020.
//

import Foundation

class UploadManager {
    static let instance = UploadManager()
    
    func createBoundary() -> String {
        var uuid = UUID().uuidString
        uuid = uuid.replacingOccurrences(of: "-", with: "")
        uuid = uuid.map { $0.lowercased() }.joined()
     
        let boundary = /*String(repeating: "-", count: 20) +*/ uuid + "\(Int(Date.timeIntervalSinceReferenceDate))"
     
        return boundary
    }
    
    func getHttpBody(forParameters parameters: RequestParameters, withBoundary boundary: String) -> Data {
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
    
    private func add(files: [FileInfo], toBody body: inout Data, withBoundary boundary: String) -> [String]? {
        var status = true
        var failedFilenames: [String]?
     
        for file in files {
            guard let filename = file.filename, let content = file.fileContents, let mimetype = file.mimeType, let name = file.name else { continue }
            status = false
            var data = Data()
     
            let fname = "thefile"
            let formattedFileInfo = ["--\(boundary)\r\n",
                                     "Content-Disposition: form-data; name=\"\(fname)\"; filename=\"\(filename)\"\r\n",
                                     "Content-Type: \(mimetype)\r\n\r\n"]
            
            if data.append(values: formattedFileInfo) {
                if data.append(values: [content]) {
                    if data.append(values: ["\r\n"]) {
                        status = true
                    }
                }
            }
     
            if status {
                body.append(data)
            } else {
                if failedFilenames == nil {
                    failedFilenames = [String]()
                }
     
                failedFilenames?.append(filename)
            }
        }
     
        return failedFilenames
    }
    
    func close(body: inout Data, usingBoundary boundary: String) {
        
        let closeString = "\r\n--\(boundary)--\r\n"
        
        
        _ = body.append(values: ["\r\n--\(boundary)--\r\n"])
    }
    
    func getBodyData(parameters: RequestParameters, files: [FileInfo], boundary: String) -> Data? {
        var body = self.getHttpBody(forParameters: parameters, withBoundary: boundary)
        let failedFilenames = self.add(files: files, toBody: &body, withBoundary: boundary)
        
        if let failed = failedFilenames {
            print("FAILED: ", failed)
        }
        
        self.close(body: &body, usingBoundary: boundary)
        
        print("REQUEST BODY\n\n", String(decoding: body, as: UTF8.self))
        
        return body
    }
}
