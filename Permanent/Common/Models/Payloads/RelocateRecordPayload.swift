//  
//  CopyOrMoveRecordPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 19.11.2020.
//

import Foundation

struct RelocateRecordPayload: Model {
    let recordVO: RecordVOPayloadData
    let folderDestVO: FolderDestVOPayloadData

    init(folderLinkId: Int, folderDestLinkId: Int, parentFolderLinkId: Int, archiveNbr: String, uploadFileName: String, recordId: Int, parentFolderId: Int) {
        self.recordVO = RecordVOPayloadData(folderLinkId: folderLinkId, parentFolderLinkId: parentFolderLinkId, archiveNbr: archiveNbr, uploadFileName: uploadFileName, recordId: recordId, parentFolderId: parentFolderId)
        self.folderDestVO = FolderDestVOPayloadData(folderLinkId: folderDestLinkId)
    }

    enum CodingKeys: String, CodingKey {
        case recordVO = "RecordVO"
        case folderDestVO = "FolderDestVO"
    }
}
