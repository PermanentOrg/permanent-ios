//  
//  FileDownloadInfoVM.swift
//  Permanent
//
//  Created by Adrian Creteanu on 19.01.2021.
//

import Foundation

struct FileDownloadInfoVM: FileDownloadInfo {
    var fileType: FileType
    var folderLinkId: Int
    var parentFolderLinkId: Int
}
