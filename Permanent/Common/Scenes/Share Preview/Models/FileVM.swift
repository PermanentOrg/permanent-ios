//  
//  FileVM.swift
//  Permanent
//
//  Created by Adrian Creteanu on 12.01.2021.
//

import Foundation

struct FileVM: File {
    var name: String
    var date: String
    var thumbStringURL: String
    
    init(folder: FolderVOData) {
        name = folder.displayName ?? ""
        date = folder.displayDT ?? ""
        thumbStringURL = folder.thumbURL500 ?? ""
    }
    
    init(record: RecordVOData) {
        name = record.displayName ?? ""
        date = record.displayDT ?? ""
        thumbStringURL = record.thumbURL500 ?? ""
    }
    
}
