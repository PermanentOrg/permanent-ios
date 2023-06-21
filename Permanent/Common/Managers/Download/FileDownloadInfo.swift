//  
//  FileDownloadInfo.swift
//  Permanent
//
//  Created by Adrian Creteanu on 19.01.2021.
//

import Foundation

protocol FileDownloadInfo {
    
    var folderLinkId: Int { get }
    
    var parentFolderLinkId: Int { get }
    
    var fileType: FileType { get }
    
}
