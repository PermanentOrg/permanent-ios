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
    let url: URL

    init(withFileURL url: URL, filename: String, name: String, mimeType: String) {
        fileContents = try? Data(contentsOf: url)
        self.filename = filename
        self.name = name
        self.mimeType = mimeType
        self.url = url
    }
}
