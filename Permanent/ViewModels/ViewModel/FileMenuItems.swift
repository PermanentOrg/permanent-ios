//
//  FileMenuItems.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.09.2026.
//

import Foundation

/// The actions one file offers, from its permissions and the list it sits in.
/// The … sheet and the long-press menu both read this list.
enum FileMenuItems {
    typealias ItemType = FileMenuViewModel.MenuItem.ItemType

    enum Place: Equatable {
        case privateFiles
        case publicFiles
        case sharedByMe(isRoot: Bool)
        case sharedWithMe(isRoot: Bool)
    }

    /// In the sheet's order, with the one destructive item last.
    static func types(for file: FileModel, in place: Place) -> [ItemType] {
        let permissions = file.permissions
        let isFolder = file.type.isFolder
        var types: [ItemType] = []

        if permissions.contains(.ownership) && (!place.isShared || permissions.contains(.share)) {
            types.append(.shareToPermanent)
        }
        if permissions.contains(.share) && !isFolder {
            types.append(.shareToAnotherApp)
        }
        if place == .privateFiles && permissions.contains(.delete) {
            types.append(.publish)
        }
        if permissions.contains(.edit) {
            types.append(.rename)
        }
        if !place.isSharedRoot {
            if permissions.contains(.move) { types.append(.move) }
            if permissions.contains(.create) { types.append(.copy) }
        }
        if permissions.contains(.read) && !isFolder {
            types.append(.download)
        }
        if place == .sharedWithMe(isRoot: true) {
            types.append(.unshare)
        } else if permissions.contains(.delete) {
            types.append(.delete)
        }
        return types
    }
}

private extension FileMenuItems.Place {
    var isShared: Bool {
        switch self {
        case .privateFiles, .publicFiles: return false
        case .sharedByMe, .sharedWithMe: return true
        }
    }

    var isSharedRoot: Bool {
        switch self {
        case .privateFiles, .publicFiles: return false
        case .sharedByMe(let isRoot), .sharedWithMe(let isRoot): return isRoot
        }
    }
}
