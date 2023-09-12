//
//  FolderInfo.swift
//  Permanent
//
//  Created by Adrian Creteanu on 03/11/2020.
//

import Foundation

class FolderInfo: NSObject, NSCoding {
    let folderId: Int
    let folderLinkId: Int
    
    init(folderId: Int, folderLinkId: Int) {
        self.folderId = folderId
        self.folderLinkId = folderLinkId
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(folderId, forKey: "folderId")
        coder.encode(folderLinkId, forKey: "folderLinkId")
    }
    
    required init?(coder: NSCoder) {
        self.folderId = coder.decodeInteger(forKey: "folderId")
        self.folderLinkId = coder.decodeInteger(forKey: "folderLinkId")
    }
}
