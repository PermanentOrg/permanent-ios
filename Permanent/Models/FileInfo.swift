//
//  FileInfo.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/10/2020.
//

import Foundation

struct FileInfo {
    var fileContents: Data?
    var mimeType: String?
    var name: String
    let url: URL
    var folder: FolderInfo

    init(withURL url: URL, named name: String, folder: FolderInfo) {
        fileContents = try? Data(contentsOf: url)

        self.name = name
        self.url = url
        mimeType = UploadManager.instance.getMimeType(forExtension: url.pathExtension)
        self.folder = folder
    }

    static func createFiles(from urls: [URL], parentFolder: FolderInfo) -> [FileInfo] {
        return urls.map {
            FileInfo(withURL: $0,
                     named: $0.lastPathComponent,
                     folder: parentFolder)
        }
    }
}
