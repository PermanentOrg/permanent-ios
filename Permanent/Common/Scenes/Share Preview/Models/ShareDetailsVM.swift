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
    
    // Additional property to track the creator account ID
    var creatorAccountId: Int?
    
    // Additional property to track the parent folder link ID for navigation
    var parentFolderLinkId: Int?
    
    // Archive number of the original archive where the share was created
    var originalArchiveNbr: String?
    
    // Clean archive name without "From" prefix
    var cleanArchiveName: String?
    
    init(model: SharebyURLVOData) {
        if let archive = model.archiveVO?.fullName {
            archiveName = String.init(format: .fromArchive, archive)
            cleanArchiveName = "The \(archive) Archive" // Format the clean name properly
        }
        if let name = model.accountVO?.fullName {
            accountName = String.init(format: .sharedBy, name)
        }
        
        archiveThumbURL = URL(string: model.archiveVO?.thumbURL200)
        
        // Store the original archive number from the share
        originalArchiveNbr = model.archiveVO?.archiveNbr
        
        sharedFileName =
            model.recordData?.displayName ??
            model.folderData?.displayName ?? ""
        
        hasAccess = model.shareVO != nil
        showPreview = model.previewToggle == 1
        status = ShareStatus.status(forValue: model.shareVO?.status)
        folderLinkId = (model.folderLinkID?.value as? Int) ?? -1
        thumbURL2000 = model.recordData?.thumbURL2000
        
        // Store the creator account ID from byAccountID field
        creatorAccountId = model.byAccountID
        
        // Store the parent folder link ID for navigation (for files)
        if let recordData = model.recordData {
            parentFolderLinkId = recordData.parentFolderLinkID
        } else {
            parentFolderLinkId = nil
        }
        
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
