//
//  ArchiveV2Models.swift
//  Permanent
//
//  Created by Lucian Cerbu on 21.07.2026.
//

import Foundation

/// The archive search response. Each item carries a `rootFolderId`, which bootstraps V2 folder
/// navigation in place of the V1 `getRoot` call.
struct ArchivesV2Response: Model {
    let items: [ArchiveV2Data]?
    let pagination: PaginationV2?
}

struct ArchiveV2Data: Model {
    /// Archive id (opaque, numeric-as-string on the wire).
    let archiveId: String?
    /// Archive number, matched string-to-string against the session's selected archive. The stable
    /// key here, since the session holds `archiveID` as an Int.
    let archiveNbr: String?
    /// The archive's top-level root folder id. Its children are the section roots, so "My Files" takes
    /// one further `/children` call to resolve.
    let rootFolderId: String?
    let name: String?
    let type: String?
    let status: String?
    let callerMembershipRole: String?
}
