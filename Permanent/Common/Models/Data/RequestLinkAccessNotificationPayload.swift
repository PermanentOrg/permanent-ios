//
//  RequestShareLinkNotificationPayload.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 26.05.2021.
//

import Foundation

class RequestLinkAccessNotificationPayload: BaseNotificationPayload {
    let name: String
    let folderLinkId: Int
    let isFolder: Bool
    
    init(name: String, folderLinkId: Int, isFolder: Bool, toArchiveId: Int, toArchiveNbr: String, toArchiveName: String) {
        self.name = name
        self.folderLinkId = folderLinkId
        self.isFolder = isFolder
        
        super.init(toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName)
    }
    
    required init?(coder: NSCoder) {
        name = coder.decodeObject(forKey: "name") as? String ?? ""
        folderLinkId = coder.decodeInteger(forKey: "folderLinkId")
        isFolder = coder.decodeBool(forKey: "isFolder")
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(folderLinkId, forKey: "folderLinkId")
        coder.encode(isFolder, forKey: "isFolder")
        
        super.encode(with: coder)
    }
    
}
