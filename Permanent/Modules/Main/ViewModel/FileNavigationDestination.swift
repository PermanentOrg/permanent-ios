//
//  FileNavigationDestination.swift
//  Permanent
//
//  Created on 18.12.2025
//  Phase 3: Navigation Migration - NavigationStack path destination enum
//

import Foundation

// MARK: - FileNavigationDestination

/// Hashable enum for NavigationStack path, representing navigation destinations
/// within the folder hierarchy.
enum FileNavigationDestination: Hashable {
    /// Navigate to a specific folder
    case folder(archiveNo: String, folderLinkId: Int, name: String)
    
    /// Navigate to a shared folder via deep link
    case deepLink(shareToken: String)
    
    // MARK: - Hashable Implementation
    
    /// Hash by identity only (folderLinkId for folders, shareToken for deep links)
    func hash(into hasher: inout Hasher) {
        switch self {
        case .folder(_, let folderLinkId, _):
            hasher.combine("folder")
            hasher.combine(folderLinkId)
        case .deepLink(let shareToken):
            hasher.combine("deepLink")
            hasher.combine(shareToken)
        }
    }
    
    // MARK: - Equatable Implementation
    
    /// Compare by folderLinkId for folders, shareToken for deep links
    static func == (lhs: FileNavigationDestination, rhs: FileNavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case let (.folder(_, lhsFolderLinkId, _), .folder(_, rhsFolderLinkId, _)):
            return lhsFolderLinkId == rhsFolderLinkId
        case let (.deepLink(lhsToken), .deepLink(rhsToken)):
            return lhsToken == rhsToken
        default:
            return false
        }
    }
    
    // MARK: - Convenience Properties
    
    /// Returns the display name for the navigation destination
    var displayName: String {
        switch self {
        case .folder(_, _, let name):
            return name
        case .deepLink(let shareToken):
            return "Shared: \(shareToken)"
        }
    }
    
    /// Returns the folder link ID if this is a folder destination
    var folderLinkId: Int? {
        switch self {
        case .folder(_, let folderLinkId, _):
            return folderLinkId
        case .deepLink:
            return nil
        }
    }
    
    /// Returns the archive number if this is a folder destination
    var archiveNo: String? {
        switch self {
        case .folder(let archiveNo, _, _):
            return archiveNo
        case .deepLink:
            return nil
        }
    }
}

// MARK: - FileNavigationDestination + FileModel Convenience

extension FileNavigationDestination {
    /// Creates a folder navigation destination from a FileModel
    /// - Parameter fileModel: The file model representing a folder
    /// - Returns: A navigation destination, or nil if the file model is not a folder
    static func from(_ fileModel: FileModel) -> FileNavigationDestination? {
        guard fileModel.type.isFolder else { return nil }
        return .folder(
            archiveNo: fileModel.archiveNo,
            folderLinkId: fileModel.folderLinkId,
            name: fileModel.name
        )
    }
}
