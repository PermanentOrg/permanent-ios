//
//  BaseNotificationPayload.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 27.09.2021.
//

import Foundation

class BaseNotificationPayload: NSObject, NSCoding {
    let toArchiveId: Int
    let toArchiveNbr: String
    let toArchiveName: String
    
    init(toArchiveId: Int, toArchiveNbr: String, toArchiveName: String) {
        self.toArchiveId = toArchiveId
        self.toArchiveNbr = toArchiveNbr
        self.toArchiveName = toArchiveName
        
        super.init()
    }
    
    required init?(coder: NSCoder) {
        toArchiveId = coder.decodeInteger(forKey: "toArchiveId")
        toArchiveNbr = coder.decodeObject(forKey: "toArchiveNbr") as? String ?? ""
        toArchiveName = coder.decodeObject(forKey: "toArchiveName") as? String ?? ""
        
        super.init()
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(toArchiveId, forKey: "toArchiveId")
        coder.encode(toArchiveNbr, forKey: "toArchiveNbr")
        coder.encode(toArchiveName, forKey: "toArchiveName")
    }
}
