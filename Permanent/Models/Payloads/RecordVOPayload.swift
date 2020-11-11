//  
//  RecordVOPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09/11/2020.
//

import Foundation

struct RecordVOPayload: Model {
    let recordVO: RecordVOPayloadData
    
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
