//  
//  CopyOrMoveRecordFolderPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 19.11.2020.
//

import Foundation

struct RelocateFolderPayload: Model {
    let folderVO: FolderVOPayloadData
    let folderDestVO: FolderDestVOPayloadData
    
    init(folderLinkId: Int, folderDestLinkId: Int) {
        self.folderVO = FolderVOPayloadData(folderLinkId: folderLinkId)
        self.folderDestVO = FolderDestVOPayloadData(folderLinkId: folderDestLinkId)
    }
    
    enum CodingKeys: String, CodingKey {
        case folderVO = "FolderVO"
        case folderDestVO = "FolderDestVO"
    }
}
