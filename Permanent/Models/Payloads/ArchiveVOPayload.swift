//  
//  ArchiveVOPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22.12.2020.
//

import Foundation

struct ArchiveVOPayload: Model {
    let archiveVO: ArchiveVOPayloadData
    
    init(archiveNbr: String) {
        self.archiveVO = ArchiveVOPayloadData(archiveNbr: archiveNbr)
    }
    
    enum CodingKeys: String, CodingKey {
        case archiveVO = "ArchiveVO"
    }
}

struct ArchiveVOPayloadData: Model {
    let archiveNbr: String
}
