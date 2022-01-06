//  
//  FileStatus.swift
//  Permanent
//
//  Created by Adrian Creteanu on 28/10/2020.
//

import Foundation

enum FileStatus {
    /// File is synced on the device. It must be displayed on the `FileListType.synced` list.
    case synced
    
    /// File is currently uploading. It must be displayed on the `FileListType.uploading` list.
    case uploading
    
    /// File is pending to be uploaded or downloaded. It must be displayed on the `FileListType.uploading` or `FileListType.downloading` list.
    case waiting
    
    /// File is currently downloading . It must be displayed on the `FileListType.downloading` list.
    case downloading
}
