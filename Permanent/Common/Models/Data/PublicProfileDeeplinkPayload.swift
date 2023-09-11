//
//  PublicProfileDeeplinkPayload.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 31.01.2023.
//

import Foundation

class PublicProfileDeeplinkPayload: Codable {
    let archiveNbr: String
    let folderArchiveNbr: String?
    let folderLinkId: String?
    let fileArchiveNbr: String?
    
    init(archiveNbr: String, folderArchiveNbr: String?, folderLinkId: String?, fileArchiveNbr: String?) {
        self.archiveNbr = archiveNbr
        self.folderArchiveNbr = folderArchiveNbr
        self.folderLinkId = folderLinkId
        self.fileArchiveNbr = fileArchiveNbr
    }
}
