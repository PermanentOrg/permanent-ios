//
//  ShareNotificationPayload.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 07.04.2021.
//

import Foundation

class ShareNotificationPayload: BaseNotificationPayload {
    let name: String
    let recordId: Int
    let folderLinkId: Int
    let archiveNbr: String
    let type: String
    let accessRole: String
    
    init(name: String, recordId: Int, folderLinkId: Int, archiveNbr: String, type: String, toArchiveId: Int, toArchiveNbr: String, toArchiveName: String, accessRole: String) {
        self.name = name
        self.recordId = recordId
        self.folderLinkId = folderLinkId
        self.archiveNbr = archiveNbr
        self.type = type
        self.accessRole = accessRole
        
        super.init(toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName)
    }
    
    required init?(coder: NSCoder) {
        name = coder.decodeObject(forKey: "name") as? String ?? ""
        recordId = coder.decodeInteger(forKey: "recordId")
        folderLinkId = coder.decodeInteger(forKey: "folderLinkId")
        archiveNbr = coder.decodeObject(forKey: "archiveNbr") as? String ?? ""
        type = coder.decodeObject(forKey: "type") as? String ?? ""
        accessRole = coder.decodeObject(forKey: "accessRole") as? String ?? ""
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(recordId, forKey: "recordId")
        coder.encode(folderLinkId, forKey: "folderLinkId")
        coder.encode(archiveNbr, forKey: "archiveNbr")
        coder.encode(type, forKey: "type")
        
        super.encode(with: coder)
    }
}
