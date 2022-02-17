//  
//  RecordVOPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09/11/2020.
//

import Foundation

struct RecordVOPayload: Model {
    let recordVO: RecordVOPayloadData
    
    init(folderLinkId: Int, parentFolderLinkId: Int, archiveNbr: String? = nil, uploadFileName: String? = nil, recordId: Int? = nil, parentFolderId: Int? = nil) {
        self.recordVO = RecordVOPayloadData(folderLinkId: folderLinkId,
                                            parentFolderLinkId: parentFolderLinkId,
                                            archiveNbr: archiveNbr,
                                            uploadFileName: uploadFileName,
                                            recordId: recordId,
                                            parentFolderId: parentFolderId)
    }
    
    enum CodingKeys: String, CodingKey {
        case recordVO = "RecordVO"
    }
}

struct RecordVOPayloadData: Model {
    let folderLinkId: Int
    let parentFolderLinkId: Int
    let archiveNbr: String?
    let uploadFileName: String?
    let recordId: Int?
    let parentFolderId: Int?
    
    enum CodingKeys: String, CodingKey {
        case folderLinkId = "folder_linkId"
        case parentFolderLinkId = "parentFolder_linkId"
        case archiveNbr
        case uploadFileName
        case recordId
        case parentFolderId
    }
}
