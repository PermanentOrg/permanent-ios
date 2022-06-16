//  
//  ShareDetailsVM.swift
//  Permanent
//
//  Created by Adrian Creteanu on 12.01.2021.
//

import Foundation

struct ShareDetailsVM: ShareDetails {
    var archiveName: String = ""
    var accountName: String = ""
    var sharedFileName: String
    var hasAccess: Bool
    var showPreview: Bool
    var archiveThumbURL: URL?
    var status: ShareStatus
    var folderLinkId: Int
    var recordId: Int?
    var fileType: FileType?
    var thumbURL2000: String?
    
    init(model: SharebyURLVOData) {
        if let archive = model.archiveVO?.fullName {
            archiveName = String.init(format: .fromArchive, archive)
        }
        if let name = model.accountVO?.fullName {
            accountName = String.init(format: .sharedBy, name)
        }
        
        archiveThumbURL = URL(string: model.archiveVO?.thumbURL200)
        sharedFileName =
            model.recordData?.displayName ??
            model.folderData?.displayName ?? ""
        
        hasAccess = model.shareVO != nil
        showPreview = model.previewToggle == 1
        status = ShareStatus.status(forValue: model.shareVO?.status)
        folderLinkId = (model.folderLinkID?.value as? Int) ?? -1
        thumbURL2000 = model.recordData?.thumbURL2000
        
        if let recordType = model.recordData?.type {
            fileType = FileType.init(rawValue: recordType )
        } else  {
            fileType = FileType.publicFolder
        }
        
        if let recordId = model.recordData?.recordID {
            self.recordId = recordId
        }
    }
}
