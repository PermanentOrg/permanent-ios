//
//  ArchiveV2Models.swift
//  Permanent
//
//  Created by Lucian Cerbu on 21.07.2026.
//

import Foundation

/// Response of Stela `GET /api/v2/archives` (archive search). Each item carries the
/// archive's `rootFolderId`, which bootstraps V2 folder navigation (replacing the V1
/// `/folder/getRoot` call). Pagination reuses the shared `PaginationV2` shape.
struct ArchivesV2Response: Model {
    let items: [ArchiveV2Data]?
    let pagination: PaginationV2?
}

struct ArchiveV2Data: Model {
    /// Archive id (opaque, numeric-as-string on the wire).
    let archiveId: String?
    /// Archive number, e.g. "01it-0000" — matched against the session's selected archive
    /// (string-to-string; the session holds `archiveID` as an Int, so `archiveNbr` is the
    /// stable key that avoids Int/String coercion).
    let archiveNbr: String?
    /// The archive's top-level root folder id (`type.folder.root.root`). Its children are
    /// the section roots (My Files / Public / Apps); the private "My Files" folder is a
    /// CHILD of it, so one further `/folders/{rootFolderId}/children` call resolves it.
    let rootFolderId: String?
    let name: String?
    let type: String?
    let status: String?
    let callerMembershipRole: String?
}
