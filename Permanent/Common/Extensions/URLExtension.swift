//  
//  URLExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 13/11/2020.
//

import Foundation
import MobileCoreServices

extension URL {
    var typeIdentifier: String? {
        return (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    }
    
    var localizedName: String? {
        return (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName
    }
    
    var mimeType: String? {
        guard
            let extUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeUnretainedValue(),
            let mimeUTI = UTTypeCopyPreferredTagWithClass(extUTI, kUTTagClassMIMEType)
        else {
            return nil
        }
        
        return mimeUTI.takeUnretainedValue() as String
    }
    
    public init?(string: String?) {
        self.init(string: string ?? "")
    }
    
    var fileSizeString: String {
        do {
            let resourceValues = try self.resourceValues(forKeys: [.fileSizeKey])
            let fileSize = resourceValues.fileSize!
            return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
        } catch {
            print("Failed to retrieve file size: \(error)")
            return "Unknown size"
        }
    }
}
