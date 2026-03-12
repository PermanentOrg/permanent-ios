//
//  SharePreviewCreateArchiveCoordinator.swift
//  Permanent
//
//  Created by Codex on 12.03.2026.
//

import Foundation

struct SharePreviewCreateArchiveCoordinator {
    struct Outcome {
        let refreshedArchives: [ArchiveVOData]
        let selectedArchive: ArchiveVOData?
    }

    func performCreateArchive(
        name: String,
        type: ArchiveType,
        existingArchiveIDs: Set<Int>,
        createArchiveRequest: (_ name: String, _ type: String) async throws -> Void,
        refreshArchives: () async -> [ArchiveVOData],
        resolveThumbnail: (ArchiveVOData) async -> ArchiveVOData
    ) async throws -> Outcome {
        try await createArchiveRequest(name, type.rawValue)

        let refreshedArchives = await refreshArchives()
        guard let createdArchive = resolveNewlyCreatedArchive(
            named: name,
            from: refreshedArchives,
            existingArchiveIDs: existingArchiveIDs
        ) else {
            return Outcome(refreshedArchives: refreshedArchives, selectedArchive: nil)
        }

        let archiveWithThumbnail = await resolveThumbnail(createdArchive)
        return Outcome(refreshedArchives: refreshedArchives, selectedArchive: archiveWithThumbnail)
    }

    private func resolveNewlyCreatedArchive(
        named name: String,
        from archives: [ArchiveVOData],
        existingArchiveIDs: Set<Int>
    ) -> ArchiveVOData? {
        let lowercasedName = name.lowercased()
        let exactNameMatch: (ArchiveVOData) -> Bool = { archive in
            archive.fullName?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == lowercasedName
        }

        return archives
            .filter { archive in
                exactNameMatch(archive) && !existingArchiveIDs.contains(archive.archiveID ?? -1)
            }
            .max { ($0.archiveID ?? 0) < ($1.archiveID ?? 0) }
            ?? archives
            .filter(exactNameMatch)
            .max { ($0.archiveID ?? 0) < ($1.archiveID ?? 0) }
    }
}
