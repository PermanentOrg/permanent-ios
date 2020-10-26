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
    var filename: String?
    var name: String?

    init(withFileURL url: URL?, filename: String, name: String, mimeType: String) {
        guard let url = url else { return }
        
        fileContents = try? Data(contentsOf: url)
        self.filename = filename
        self.name = name
        self.mimeType = mimeType
    }
}
