//
//  ArchiveDropdownMenuOption.swift
//  DropdownMenu
//

import Foundation

// We are going to use this type with ForEach, so we need to conform it to
// Hashable protocol.
struct ArchiveDropdownMenuOption: Identifiable, Hashable {
	let id = UUID().uuidString
	let archiveName: String
    let archiveThumbnailAddress: String
    let archiveAccessRole: String
    let archiveNbr: String
    let isArchiveSelected: Bool
}

extension ArchiveDropdownMenuOption {
    static let testSingleArchive = ArchiveDropdownMenuOption(archiveName: "", archiveThumbnailAddress: "", archiveAccessRole: "", archiveNbr: "", isArchiveSelected: false)
}
