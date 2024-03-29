//
//  FileType.swift
//  Permanent
//
//  Created by Adrian Creteanu on 15/10/2020.
//

import Foundation

enum FileType: String, Codable {
    case publicFolder = "type.folder.public"
    case privateFolder = "type.folder.private"
    case publicRootFolder = "type.folder.root.public"
    case privateRootFolder = "type.folder.root.private"
    case sharedFolder = "type.share.folder"
    case image = "type.record.image"
    case video = "type.record.video"
    case audio = "type.record.audio"
    case pdf = "type.record.pdf"
    case miscellaneous = "type.record.misc"
    case workspace = "type.workspace"
    
    var isFolder: Bool {
        switch self {
        case .image, .miscellaneous, .video, .pdf, .audio:
            return false
            
        default:
            return true
        }
    }
}
