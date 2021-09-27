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
    
    init(name: String, folderLinkId: Int, toArchiveId: Int, toArchiveNbr: String, toArchiveName: String) {
        self.name = name
        self.folderLinkId = folderLinkId
        
        super.init(toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName)
    }
    
    required init?(coder: NSCoder) {
        name = coder.decodeObject(forKey: "name") as? String ?? ""
        folderLinkId = coder.decodeInteger(forKey: "folderLinkId")
        
        super.init(coder: coder)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(folderLinkId, forKey: "folderLinkId")
        
        super.encode(with: coder)
    }
    
}
