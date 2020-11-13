//  
//  RecordVOPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09/11/2020.
//

import Foundation

struct RecordVOPayload: Model {
    let recordVO: RecordVOPayloadData
    
    init(folderLinkId: Int) {
        self.recordVO = RecordVOPayloadData(folderLinkId: folderLinkId)
    }
    
    enum CodingKeys: String, CodingKey {
        case recordVO = "RecordVO"
    }
}

struct RecordVOPayloadData: Model {
    let folderLinkId: Int
    
    enum CodingKeys: String, CodingKey {
        case folderLinkId = "folder_linkId"
    }
}
