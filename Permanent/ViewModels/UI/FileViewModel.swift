//
//  FileViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

struct FileViewModel: Equatable {
    let thumbnailURL: String?
    let name: String
    let date: String
    let type: FileType
    
    let archiveId: Int
    let archiveNo: String
    
    let recordId: Int
    
    let folderId: Int
    let folderLinkId: Int
    var fileStatus: FileStatus = .synced
    
    init(model: FileInfo) {
        self.name = model.name
        self.date = DateUtils.currentDate
        
        self.thumbnailURL = nil
        self.type = .image // TODO:
        self.archiveId = -1
        self.archiveNo = ""
        self.recordId = -1
        self.folderId = model.folder.folderId
        self.folderLinkId = model.folder.folderLinkId
        self.fileStatus = .uploading
    }
    
    init(model: ChildItemVO) {
        self.name = model.displayName ?? "-"
        self.date = model.displayDT != nil ?
            String(model.displayDT!.prefix(while: { $0 != "T" })) : "-"
            
        self.thumbnailURL = model.thumbURL200
        self.type = FileType(rawValue: model.type ?? "") ?? FileType.miscellaneous
        
        self.archiveId = model.archiveID ?? -1
        self.archiveNo = model.archiveNbr ?? ""
        
        self.recordId = model.recordID ?? -1
        
        self.folderId = model.folderID ?? -1
        self.folderLinkId = model.folderLinkID ?? -1
    }
    
    init(model: MinFolderVO) {
        self.name = model.displayName ?? "-"
        self.date = model.displayDT != nil ?
            String(model.displayDT!.prefix(while: { $0 != "T" })) : "-"
            
        self.thumbnailURL = model.thumbURL200
        self.type = FileType(rawValue: model.type ?? "") ?? FileType.miscellaneous
        
        self.archiveId = model.archiveID ?? -1
        self.archiveNo = model.archiveNbr ?? ""
        
        self.recordId = model.childItemVOS?.first?.recordID ?? -1 // TODO:
        
        self.folderId = model.folderID ?? -1
        self.folderLinkId = model.folderLinkID ?? -1
    }
}
