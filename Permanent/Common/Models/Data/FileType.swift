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

    /// Maps a V2 `type` string to a `FileType`. Folders serialize a pretty type that doesn't match the
    /// raw values and must be mapped explicitly; records keep the raw string.
    static func fromV2(typeString: String?, isFolder: Bool) -> FileType {
        guard isFolder else {
            return FileType(rawValue: typeString ?? "") ?? .miscellaneous
        }
        switch typeString {
        case "public":                      return .publicFolder
        case "public-root", "public_root":  return .publicRootFolder
        case "private-root", "private_root": return .privateRootFolder
        case "share", "share-root", "share_root": return .sharedFolder
        case "private":                     return .privateFolder
        default:                            return .privateFolder // sensible default on the Private Files path
        }
    }
}
