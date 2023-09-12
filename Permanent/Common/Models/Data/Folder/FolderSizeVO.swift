//  
//  FolderSizeVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

struct FolderSizeVO: Codable {
    let folderSizeID, folderLinkID, archiveID, folderID: Int?
    let parentFolderLinkID, parentFolderID, myFileSizeShallow, myFileSizeDeep: Int?
    let myFolderCountShallow, myFolderCountDeep, myRecordCountShallow, myRecordCountDeep: Int?
    let myAudioCountShallow, myAudioCountDeep, myDocumentCountShallow, myDocumentCountDeep: Int?
    let myExperienceCountShallow, myExperienceCountDeep, myImageCountShallow, myImageCountDeep: Int?
    let myVideoCountShallow, myVideoCountDeep, allFileSizeShallow, allFileSizeDeep: Int?
    let allFolderCountShallow, allFolderCountDeep, allRecordCountShallow, allRecordCountDeep: Int?
    let allAudioCountShallow, allAudioCountDeep, allDocumentCountShallow, allDocumentCountDeep: Int?
    let allExperienceCountShallow, allExperienceCountDeep, allImageCountShallow, allImageCountDeep: Int?
    let allVideoCountShallow, allVideoCountDeep: Int?
    let lastExecuteDT, lastExecuteReason, nextExecuteDT, displayName: String?
    let folderSizeVODescription, type, status: String?
    let position: Int?
    let recursive: JSONAny?
    let createdDT, updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case folderSizeID = "folder_sizeId"
        case folderLinkID = "folder_linkId"
        case archiveID = "archiveId"
        case folderID = "folderId"
        case parentFolderLinkID = "parentFolder_linkId"
        case parentFolderID = "parentFolderId"
        case myFileSizeShallow, myFileSizeDeep, myFolderCountShallow, myFolderCountDeep, myRecordCountShallow, myRecordCountDeep, myAudioCountShallow, myAudioCountDeep, myDocumentCountShallow, myDocumentCountDeep, myExperienceCountShallow, myExperienceCountDeep, myImageCountShallow, myImageCountDeep, myVideoCountShallow, myVideoCountDeep, allFileSizeShallow, allFileSizeDeep, allFolderCountShallow, allFolderCountDeep, allRecordCountShallow, allRecordCountDeep, allAudioCountShallow, allAudioCountDeep, allDocumentCountShallow, allDocumentCountDeep, allExperienceCountShallow, allExperienceCountDeep, allImageCountShallow, allImageCountDeep, allVideoCountShallow, allVideoCountDeep, lastExecuteDT, lastExecuteReason, nextExecuteDT, displayName
        case folderSizeVODescription = "description"
        case type, status, position, recursive, createdDT, updatedDT
    }
}
