//
//  FolderVOPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09/11/2020.
//

import Foundation

struct FolderVOPayload: Model {
    let folderVO: FolderVOPayloadData
    
    enum CodingKeys: String, CodingKey {
        case folderVO = "FolderVO"
    }
}

struct FolderVOPayloadData: Model {
    let folderLinkId: Int

    enum CodingKeys: String, CodingKey {
        case folderLinkId = "folder_linkId"
    }
}
