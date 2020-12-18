//  
//  SharedFileViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 17.12.2020.
//

import Foundation

struct SharedFileViewModel {
    let name: String
    let date: String
    let thumbnailURL: String?
    let archiveThumbnailURL: String?
    let type: FileType
    
    init(model: ItemVO, thumbURL: String?) {
        self.name = model.displayName ?? "-"
        self.date = model.displayDT != nil ?
            model.displayDT!.dateOnly : "-"
        
        self.thumbnailURL = model.thumbURL200
        self.archiveThumbnailURL = thumbURL
        
        self.type = FileType(rawValue: model.type ?? "") ?? FileType.miscellaneous
    }
    
}
