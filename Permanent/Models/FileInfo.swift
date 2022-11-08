//
//  FileInfo.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/10/2020.
//

import Foundation

class FileInfo: NSObject, NSCoding {
    var id: String = NSUUID().uuidString
    var archiveId: Int
    
    var fileContents: Data?
    var mimeType: String? {
        url.mimeType
    }
    var name: String
    var url: URL
    var folder: FolderInfo
    
    var didFailUpload = false
    
    static func == (lhs: FileInfo, rhs: FileInfo) -> Bool {
        return lhs.name == rhs.name && lhs.url == rhs.url && lhs.folder.folderId == rhs.folder.folderId && lhs.archiveId == rhs.archiveId
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? FileInfo else { return false }
        return name == rhs.name && url == rhs.url && folder.folderId == rhs.folder.folderId
    }

    init(withURL url: URL, named name: String, folder: FolderInfo, archiveId: Int = -1, loadInMemory: Bool = false) {
        self.name = name
        self.url = url
        self.folder = folder
        self.archiveId = archiveId
        
        if loadInMemory {
            fileContents = try? Data(contentsOf: url)
        }
    }

    static func createFiles(from urls: [URL], parentFolder: FolderInfo, loadInMemory: Bool = false) -> [FileInfo] {
        let files = urls.map { (url) -> FileInfo in
            var fileName = url.lastPathComponent
            if url.lastPathComponent.contains("FullSizeRender") {
                let fileExtention = url.lastPathComponent.components(separatedBy: ".").last ?? ""
                fileName = url.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
                if fileExtention.isNotEmpty { fileName.append(".\(fileExtention)") }
            }
            return FileInfo(withURL: url, named: fileName, folder: parentFolder, loadInMemory: loadInMemory)
        }
        return files
    }

    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
        
        coder.encode(archiveId, forKey: "archiveId")
        
        coder.encode(name, forKey: "name")
        coder.encode(url, forKey: "url")
        coder.encode(folder, forKey: "folder")
        coder.encode(didFailUpload, forKey: "didFailUpload")
    }
    
    required convenience init?(coder: NSCoder) {
        let name = coder.decodeObject(forKey: "name") as! String
        let url = coder.decodeObject(forKey: "url") as! URL
        let folder = coder.decodeObject(forKey: "folder") as! FolderInfo
        let archiveId = coder.decodeInteger(forKey: "archiveId")
        
        self.init(withURL: url, named: name, folder: folder, archiveId: archiveId)
        
        id = coder.decodeObject(forKey: "id") as! String
        didFailUpload = coder.decodeBool(forKey: "didFailUpload")
    }
}
