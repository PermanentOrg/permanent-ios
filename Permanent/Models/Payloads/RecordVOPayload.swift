//  
//  RecordVOPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09/11/2020.
//

import Foundation

struct RecordVOPayload: Model {
    let recordVO: RecordVOPayloadData
    
    init(folderLinkId: Int, parentFolderLinkId: Int) {
        self.recordVO = RecordVOPayloadData(folderLinkId: folderLinkId,
                                            parentFolderLinkId: parentFolderLinkId)
    }
    
    enum CodingKeys: String, CodingKey {
        case recordVO = "RecordVO"
    }
}

struct RecordVOPayloadData: Model {
    let folderLinkId: Int
    let parentFolderLinkId: Int
    
    enum CodingKeys: String, CodingKey {
        case folderLinkId = "folder_linkId"
        case parentFolderLinkId = "parentFolder_linkId"
    }
}
