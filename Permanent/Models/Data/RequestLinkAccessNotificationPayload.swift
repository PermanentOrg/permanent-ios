//
//  RequestShareLinkNotificationPayload.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 26.05.2021.
//

import Foundation

class RequestLinkAccessNotificationPayload: NSObject, NSCoding {
    
    let name: String
    let folderLinkId: Int
    
    init(name: String, folderLinkId: Int) {
        self.name = name
        self.folderLinkId = folderLinkId
        
        super.init()
    }
    
    required init?(coder: NSCoder) {
        name = coder.decodeObject(forKey: "name") as? String ?? ""
        folderLinkId = coder.decodeInteger(forKey: "folderLinkId")
        
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(folderLinkId, forKey: "folderLinkId")
    }
    
}
