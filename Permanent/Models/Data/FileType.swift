//
//  FileType.swift
//  Permanent
//
//  Created by Adrian Creteanu on 15/10/2020.
//

import Foundation

enum FileType: String {
    case publicFolder = "type.folder.public"
    case privateFolder = "type.folder.private"
    case publicRootFolder = "type.folder.root.public"
    case privateRootFolder = "type.folder.root.private"
    case image = "type.record.image"
    case video = "type.record.video"
    case miscellaneous = "type.record.misc"
    
    var isFolder: Bool {
        switch self {
        case .image, .miscellaneous, .video:
            return false
            
        default:
            return true
        }
    }
}
