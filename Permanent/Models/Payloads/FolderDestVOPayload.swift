//
//  FolderVOPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09/11/2020.
//

import Foundation

struct FolderDestVOPayload: Model {
    let folderVO: FolderDestVOPayloadData
    
    init(folderLinkId: Int) {
        self.folderVO = FolderDestVOPayloadData(folderLinkId: folderLinkId)
    }
    
    enum CodingKeys: String, CodingKey {
        case folderVO = "FolderDestVO"
    }
}

struct FolderDestVOPayloadData: Model {
    let folderLinkId: Int

    enum CodingKeys: String, CodingKey {
        case folderLinkId = "folder_linkId"
    }
}
