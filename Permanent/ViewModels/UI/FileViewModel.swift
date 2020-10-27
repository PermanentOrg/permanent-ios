//
//  FileViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

struct FileViewModel {
    let thumbnail: String
    let name: String
    let date: String
    let type: FileType
    let archiveNo: String
    let folderId: Int
    let folderLinkId: Int
    
    init(model: FileInfo) {
        self.name = model.filename ?? "-"
        self.date = DateUtils.currentDate
        
        self.thumbnail = "-"
        self.type = .image // TODO
        self.archiveNo = ""
        self.folderId = -1
        self.folderLinkId = -1
    }
    
    init(model: ChildItemVO) {
        self.name = model.displayName ?? "-"
        self.date = model.displayDT != nil ?
            String(model.displayDT!.prefix(while: { $0 != "T" })) : "-"
            
        self.thumbnail = model.thumbURL200 ?? "-"
        self.type = FileType(rawValue: model.type ?? "") ?? FileType.miscellaneous
        
        self.archiveNo = model.archiveNbr ?? ""
        self.folderId = model.folderID ?? -1
        self.folderLinkId = model.folderLinkID ?? -1
    }
    
    init(model: MinFolderVO) {
        self.name = model.displayName ?? "-"
        self.date = model.displayDT != nil ?
            String(model.displayDT!.prefix(while: { $0 != "T" })) : "-"
            
        self.thumbnail = model.thumbURL200 ?? "-"
        self.type = FileType(rawValue: model.type ?? "") ?? FileType.miscellaneous
        
        self.archiveNo = model.archiveNbr ?? ""
        self.folderId = model.folderID ?? -1
        self.folderLinkId = model.folderLinkID ?? -1
    }
}
