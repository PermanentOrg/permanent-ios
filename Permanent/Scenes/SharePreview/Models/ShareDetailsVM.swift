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
    //var sharedFileName: String

    init(model: SharebyURLVOData) {
        if let archive = model.archiveVO?.fullName {
            archiveName = String.init(format: .fromArchive, archive)
        }
        if let name = model.accountVO?.fullName {
            accountName = String.init(format: .sharedBy, name)
        }
        
    }
    
}
