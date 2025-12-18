//
//  FileItemViewModel.swift
//  Permanent
//
//  Created by Copilot on 17/12/2025.
//

import Foundation
import SwiftUI

/// SwiftUI-friendly view model wrapper for FileModel
struct FileItemViewModel: Identifiable {
    let id: Int
    let name: String
    let date: String
    let type: FileType
    let size: Int64
    let thumbnailURL: String?
    let thumbnailURL2000: String?
    let fileStatus: FileStatus
    let isFolder: Bool
    let hasShares: Bool
    let permissions: [Permission]
    
    // Selection state
    var isSelected: Bool = false
    var isSelectionMode: Bool = false
    
    // Display properties
    var displayName: String { name }
    var displayDate: String { date }
    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var iconName: String {
        if isFolder {
            return "folder.fill"
        }
        
        switch type {
        case .image: return "photo"
        case .video: return "video.fill"
        case .audio: return "music.note"
        case .pdf: return "doc.text.fill"
        case .miscellaneous, .workspace: return "doc"
        case .publicFolder, .privateFolder, .publicRootFolder, .privateRootFolder, .sharedFolder:
            return "folder.fill"
        }
    }
    
    var statusColor: Color {
        switch fileStatus {
        case .synced: return .primary
        case .uploading: return .blue
        case .failed: return .red
        case .downloading: return .orange
        case .waiting: return .gray
        }
    }
    
    var canShowMore: Bool {
        permissions.contains(.delete) || permissions.contains(.edit)
    }
    
    init(from model: FileModel) {
        self.id = model.recordId
        self.name = model.name
        self.date = model.date
        self.type = model.type
        self.size = model.size
        self.thumbnailURL = model.thumbnailURL
        self.thumbnailURL2000 = model.thumbnailURL2000
        self.fileStatus = model.fileStatus
        self.isFolder = model.type.isFolder
        self.hasShares = !model.minArchiveVOS.isEmpty
        self.permissions = model.permissions
    }
}
