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
    let folderLinkId: Int
    
    init(model: ChildItemVO) {
        self.name = model.displayName ?? "-"
        self.date = model.displayDT ?? "-"
        self.thumbnail = model.thumbURL200 ?? "-"
        self.type = FileType(rawValue: model.type ?? "") ?? FileType.miscellaneous
        
        self.archiveNo = model.archiveNbr ?? ""
        self.folderLinkId = model.folderLinkID ?? 0
    }
    
    init(model: MinFolderVO) {
        self.name = model.displayName ?? "-"
        self.date = model.displayDT ?? "-"
        self.thumbnail = model.thumbURL200 ?? "-"
        self.type = FileType(rawValue: model.type ?? "") ?? FileType.miscellaneous
        
        self.archiveNo = model.archiveNbr ?? ""
        self.folderLinkId = model.folderLinkID ?? 0
    }
}
