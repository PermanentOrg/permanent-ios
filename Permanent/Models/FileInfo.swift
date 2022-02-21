//
//  FileInfo.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/10/2020.
//

import Foundation

class FileInfo: NSObject, NSCoding {
    var id: String = NSUUID().uuidString
    
    var fileContents: Data?
    var mimeType: String? {
        url.mimeType
    }
    var name: String
    var url: URL
    var folder: FolderInfo
    
    var didFailUpload = false
    
    static func == (lhs: FileInfo, rhs: FileInfo) -> Bool {
        return lhs.name == rhs.name && lhs.url == rhs.url && lhs.folder.folderId == rhs.folder.folderId
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? FileInfo else { return false }
        return name == rhs.name && url == rhs.url && folder.folderId == rhs.folder.folderId
    }

    init(withURL url: URL, named name: String, folder: FolderInfo, loadInMemory: Bool = false) {
        self.name = name
        self.url = url
        self.folder = folder
        
        if loadInMemory {
            fileContents = try? Data(contentsOf: url)
        }
    }

    static func createFiles(from urls: [URL], parentFolder: FolderInfo, loadInMemory: Bool = false) -> [FileInfo] {
        let files = urls.map { FileInfo(withURL: $0, named: $0.lastPathComponent, folder: parentFolder, loadInMemory: loadInMemory) }
        
        return files
    }

    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
        
        coder.encode(name, forKey: "name")
        coder.encode(url, forKey: "url")
        coder.encode(folder, forKey: "folder")
        coder.encode(didFailUpload, forKey: "didFailUpload")
    }
    
    required convenience init?(coder: NSCoder) {
        let name = coder.decodeObject(forKey: "name") as! String
        let url = coder.decodeObject(forKey: "url") as! URL
        let folder = coder.decodeObject(forKey: "folder") as! FolderInfo
        
        self.init(withURL: url, named: name, folder: folder)
        
        id = coder.decodeObject(forKey: "id") as! String
        didFailUpload = coder.decodeBool(forKey: "didFailUpload")
    }
}
