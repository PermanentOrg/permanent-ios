//  
//  FileVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 11/11/2020.
//

import Foundation

struct FileVO: Model {
    let fileID, size: Int?
    let format: String?
    let parentFileID: Int?
    let contentType, contentVersion: String?
    let s3Version: JSONAny? // TODO
    let s3VersionID, md5Checksum, cloud1, cloud2: String?
    let cloud3: String?
    let archiveID, height, width: Int?
    let durationInSecs: Int?
    let fileURL, downloadURL: String?
    let urlDT, status, type, createdDT: String?
    let updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case fileID = "fileId"
        case size, format
        case parentFileID = "parentFileId"
        case contentType, contentVersion, s3Version
        case s3VersionID = "s3VersionId"
        case md5Checksum, cloud1, cloud2, cloud3
        case archiveID = "archiveId"
        case height, width, durationInSecs, fileURL, downloadURL, urlDT, status, type, createdDT, updatedDT
    }
}
