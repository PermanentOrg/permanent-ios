//
//  FilesViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.05.2026.
//

import XCTest
@testable import Permanent

final class FilesViewModelTests: XCTestCase {

    private func makeRecordFile(name: String = "photo.jpg") -> FileModel {
        return FileModel(
            name: name,
            recordId: 100,
            folderLinkId: 1,
            archiveNbr: "0001-0000",
            type: "type.record.image",
            permissions: [.read]
        )
    }

    private func makeFolderFile(name: String = "My Folder") -> FileModel {
        return FileModel(
            name: name,
            recordId: 0,
            folderLinkId: 2,
            archiveNbr: "0001-0000",
            type: "type.folder.public",
            permissions: [.read]
        )
    }

    // MARK: - Stela V2 children decode (PR1 — model extension)

    private func decodeChildren(_ json: String) -> FolderChildrenV2Response? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: data)
    }

    /// A folder child (nested parentFolder + thumbnailUrls, pretty type, non-numeric
    /// archiveNumber) and a record child (flat fields, raw type).
    private let stelaChildrenJSON = """
    {
      "items": [
        {
          "folderId": "10",
          "displayName": "Private Folder",
          "archiveNumber": "0001-test",
          "type": "private",
          "status": "ok",
          "folderLinkId": "11",
          "parentFolder": { "id": "2", "folderLinkId": "3" },
          "thumbnailUrls": { "200": "https://t/200", "500": "https://t/500" }
        },
        {
          "recordId": "8",
          "displayName": "photo.jpg",
          "archiveNumber": "0001-0008",
          "type": "type.record.image",
          "status": "ok",
          "folderLinkId": "9",
          "parentFolderId": "10",
          "parentFolderLinkId": "11",
          "thumbUrl200": "https://r/200"
        }
      ],
      "pagination": { "nextCursor": "abc" }
    }
    """

    func testStelaChildren_Decode_MixedFolderAndRecord() {
        let resp = decodeChildren(stelaChildrenJSON)
        XCTAssertEqual(resp?.items?.count, 2)
        XCTAssertEqual(resp?.pagination?.nextCursor, "abc")
        XCTAssertEqual(resp?.items?[0].isFolder, true)
        XCTAssertEqual(resp?.items?[1].isFolder, false)
    }

    func testStelaChildren_Folder_ResolvesNestedParentAndThumbnail() {
        let folder = decodeChildren(stelaChildrenJSON)?.items?[0]
        XCTAssertEqual(folder?.resolvedParentFolderId, "2")
        XCTAssertEqual(folder?.resolvedParentFolderLinkId, "3") // nested for folders
        XCTAssertEqual(folder?.bestThumbnailURL, "https://t/500") // 256 absent → falls back to 500
    }

    func testStelaChildren_Record_ResolvesFlatParentAndThumbnail() {
        let record = decodeChildren(stelaChildrenJSON)?.items?[1]
        XCTAssertEqual(record?.resolvedParentFolderLinkId, "11") // flat for records
        XCTAssertEqual(record?.bestThumbnailURL, "https://r/200")
    }

    // MARK: - FileModel(model: FolderChildV2Data) mapping (PR2)

    func testFileModelFromV2_Folder_MapsPrettyTypeAndIds() {
        let folder = decodeChildren(stelaChildrenJSON)!.items![0]
        let file = FileModel(model: folder, permissions: [.read], accessRole: .viewer)
        XCTAssertEqual(file.type, .privateFolder)   // pretty "private" → .privateFolder, not .miscellaneous
        XCTAssertEqual(file.folderId, 10)           // String → Int at the boundary
        XCTAssertEqual(file.folderLinkId, 11)
        XCTAssertEqual(file.parentFolderLinkId, 3)  // resolved from nested parentFolder
        XCTAssertEqual(file.recordId, -1)           // folders carry no record id
        XCTAssertEqual(file.name, "Private Folder")
    }

    func testFileModelFromV2_ArchiveNumberStaysStringNeverIntConverted() {
        let folder = decodeChildren(stelaChildrenJSON)!.items![0]
        let file = FileModel(model: folder, permissions: [.read], accessRole: .viewer)
        // "0001-test" is non-numeric — it must pass through as a String, never hit intId().
        XCTAssertEqual(file.archiveNo, "0001-test")
    }

    func testFileModelFromV2_Record_MapsRawTypeAndFlatIds() {
        let record = decodeChildren(stelaChildrenJSON)!.items![1]
        let file = FileModel(model: record, permissions: [.read], accessRole: .viewer)
        XCTAssertEqual(file.type, .image)            // raw "type.record.image"
        XCTAssertEqual(file.recordId, 8)
        XCTAssertEqual(file.folderId, -1)
        XCTAssertEqual(file.parentFolderLinkId, 11)  // flat for records
        XCTAssertEqual(file.archiveNo, "0001-0008")
    }

    func testFileModelFromV2_CopyingStatus_NotAccessible() {
        let json = """
        { "items": [ { "folderId": "5", "displayName": "Busy", "type": "private", "status": "copying" } ] }
        """
        let file = FileModel(model: decodeChildren(json)!.items![0], permissions: [.read], accessRole: .viewer)
        XCTAssertEqual(file.thumbStatus, .copying)
        XCTAssertFalse(file.canBeAccessed) // copying/moving items stay non-tappable, as on V1
    }

    // MARK: - Upload dedupe: V2 child → ItemVO matcher (post-upload dedupe migration)

    /// The V2 folder listing feeds the existing ItemVO dedupe matcher via
    /// `toMatchableItemVOs()` — the SAME production pipeline `UploadManager.fetchFolderContents`
    /// runs, not a re-implementation. This is the correctness-critical path: a miss would
    /// create a duplicate record.
    func testUploadDedupe_V2ChildAdaptsToItemVO_MatchesByUploadFileName() {
        let json = """
        {
          "items": [
            { "folderId": "10", "displayName": "Sub", "type": "private", "status": "ok" },
            { "recordId": "8", "displayName": "Rewritten By Exif", "type": "type.record.image",
              "status": "ok", "uploadFileName": "IMG_0111.heic", "size": 2048 }
          ]
        }
        """
        let items = (decodeChildren(json)?.items ?? []).toMatchableItemVOs()
        XCTAssertEqual(items.count, 1) // the subfolder is filtered out — dedupe matches files only

        // Exact uploadFileName match even though displayName was rewritten from EXIF.
        XCTAssertNotNil(items.record(forUploadName: "IMG_0111.heic", size: 2048))
        // Same name, different byte count → NOT a match (guards same-name-different-content).
        XCTAssertNil(items.record(forUploadName: "IMG_0111.heic", size: 9999))
        // Different name → no match.
        XCTAssertNil(items.record(forUploadName: "OTHER.heic", size: 2048))
        // Name match with unknown picked size → matches (legacy name-only fallback).
        XCTAssertNotNil(items.record(forUploadName: "IMG_0111.heic", size: nil))
    }

    /// When the V2 record has no uploadFileName, the matcher falls back to the
    /// extension-stripped displayName — same behaviour as the V1 path.
    func testUploadDedupe_V2Child_DisplayNameFallbackWhenNoUploadFileName() {
        let json = """
        { "items": [ { "recordId": "8", "displayName": "Scan", "type": "type.record.document",
          "status": "ok", "size": 100 } ] }
        """
        let items = (decodeChildren(json)?.items ?? []).toMatchableItemVOs()
        XCTAssertNotNil(items.record(forUploadName: "Scan.pdf", size: 100))
    }

    /// Invariant-3 sentinel: a decodable 2xx body MISSING the `items` key must decode with
    /// `items == nil` (contract failure → UploadManager falls back to V1), while a
    /// present-but-EMPTY array decodes non-nil (folder legitimately verified empty).
    /// Collapsing the two would let a malformed 200 green-light a duplicate upload.
    func testUploadDedupe_MissingItemsKeyDecodesNil_EmptyArrayDecodesEmpty() {
        XCTAssertNotNil(decodeChildren("{}"), "body without items should still decode")
        XCTAssertNil(decodeChildren("{}")?.items, "missing items key must be nil, not []")
        XCTAssertNotNil(decodeChildren("{ \"items\": [] }")?.items, "empty items array must stay non-nil")
        XCTAssertEqual(decodeChildren("{ \"items\": [] }")?.items?.count, 0)
    }

    func testFileModelFromV2_PopulatesSharesBadge() {
        let json = """
        {
          "items": [
            {
              "folderId": "10", "displayName": "Shared Folder", "type": "private", "status": "ok",
              "shares": [
                { "id": "55", "accessRole": "access.role.viewer", "status": "status.generic.ok",
                  "archive": { "id": "77", "name": "Jane Doe", "thumbUrl200": "https://a/200" } }
              ]
            }
          ]
        }
        """
        let file = FileModel(model: decodeChildren(json)!.items![0], permissions: [.read], accessRole: .viewer)
        // The "shared item" badge keys off minArchiveVOS — must survive the V2 mapping.
        XCTAssertEqual(file.minArchiveVOS.count, 1)
        XCTAssertEqual(file.minArchiveVOS.first?.name, "Jane Doe")
        XCTAssertEqual(file.minArchiveVOS.first?.shareId, 55)
        XCTAssertEqual(file.minArchiveVOS.first?.archiveID, 77)
    }

    func testFileModelFromV2_NoShares_EmptyBadge() {
        let folder = decodeChildren(stelaChildrenJSON)!.items![0]
        XCTAssertTrue(FileModel(model: folder, permissions: [.read], accessRole: .viewer).minArchiveVOS.isEmpty)
    }

    // MARK: - Client-side sort (PR3 — /children has no sort param)

    func testSort_NameAscending_IsCaseInsensitive() {
        let vm = FilesViewModel()
        vm.activeSortOption = .nameAscending
        let input = [makeRecordFile(name: "banana"), makeRecordFile(name: "Apple"), makeRecordFile(name: "cherry")]
        XCTAssertEqual(vm.sortedByActiveOption(input).map { $0.name }, ["Apple", "banana", "cherry"])
    }

    func testSort_NameDescending() {
        let vm = FilesViewModel()
        vm.activeSortOption = .nameDescending
        let input = [makeRecordFile(name: "Apple"), makeRecordFile(name: "cherry"), makeRecordFile(name: "banana")]
        XCTAssertEqual(vm.sortedByActiveOption(input).map { $0.name }, ["cherry", "banana", "Apple"])
    }

    func testSort_TypeAscending_FoldersBeforeRecords() {
        let vm = FilesViewModel()
        vm.activeSortOption = .typeAscending
        let input = [makeRecordFile(name: "a"), makeFolderFile(name: "b")]
        XCTAssertEqual(vm.sortedByActiveOption(input).first?.type.isFolder, true)
    }

    func testSort_DateAscending_UsesCreatedDate() {
        let vm = FilesViewModel()
        vm.activeSortOption = .dateAscending
        let old = """
        { "items": [ { "recordId": "1", "displayName": "old", "type": "type.record.image", "displayDate": "2020-01-01T00:00:00" } ] }
        """
        let new = """
        { "items": [ { "recordId": "2", "displayName": "new", "type": "type.record.image", "displayDate": "2024-01-01T00:00:00" } ] }
        """
        let oldFile = FileModel(model: decodeChildren(old)!.items![0], permissions: [.read], accessRole: .viewer)
        let newFile = FileModel(model: decodeChildren(new)!.items![0], permissions: [.read], accessRole: .viewer)
        XCTAssertEqual(vm.sortedByActiveOption([newFile, oldFile]).map { $0.name }, ["old", "new"])
    }

    // MARK: - Stela date parsing (B3 — the client-side date sort must tolerate the timestamp
    // shapes Stela emits; fractional-second and Postgres forms previously collapsed to
    // .distantPast, silently degenerating the sort to server order).

    func testParseSortDate_HandlesAllStelaTimestampFormats() {
        XCTAssertNotEqual(FilesViewModel.parseSortDate("2025-10-09T08:35:55Z"), .distantPast, "plain ISO8601")
        XCTAssertNotEqual(FilesViewModel.parseSortDate("2025-10-09T08:35:55.000Z"), .distantPast, "fractional ISO8601 (JS toISOString)")
        XCTAssertNotEqual(FilesViewModel.parseSortDate("2025-10-09 08:35:55+00"), .distantPast, "Postgres timestamptz")
        XCTAssertNotEqual(FilesViewModel.parseSortDate("2025-10-09T08:35:55"), .distantPast, "zone-less local")
        // Missing / unparseable still sort oldest.
        XCTAssertEqual(FilesViewModel.parseSortDate("not-a-date"), .distantPast)
        XCTAssertEqual(FilesViewModel.parseSortDate(nil), .distantPast)
        XCTAssertEqual(FilesViewModel.parseSortDate(""), .distantPast)
    }

    func testParseSortDate_SameInstantAcrossFormatsIsEqual() {
        // The same instant in all four shapes must parse to ONE Date, so a mixed listing
        // whose fields arrive in different formats still sorts coherently. The zone-less
        // case is the regression pin: without a UTC anchor it parses in device-local time
        // and lands up to a full UTC-offset away from the other three (skewing mixed
        // record/folder date sorts on any non-UTC device).
        let iso = FilesViewModel.parseSortDate("2025-10-09T08:35:55Z")
        XCTAssertNotEqual(iso, .distantPast)
        XCTAssertEqual(iso, FilesViewModel.parseSortDate("2025-10-09T08:35:55.000Z"))
        XCTAssertEqual(iso, FilesViewModel.parseSortDate("2025-10-09 08:35:55+00"))
        XCTAssertEqual(iso, FilesViewModel.parseSortDate("2025-10-09T08:35:55"), "zone-less Stela timestamps are server-UTC and must parse UTC-anchored")
    }

    func testSort_DateAscending_MixedFractionalAndPostgresFormats() {
        let vm = FilesViewModel()
        vm.activeSortOption = .dateAscending
        // Three real instants, each in a different Stela format; expect oldest → newest.
        let a = """
        { "items": [ { "recordId": "1", "displayName": "2023", "type": "type.record.image", "displayDate": "2023-01-01 00:00:00+00" } ] }
        """
        let b = """
        { "items": [ { "recordId": "2", "displayName": "2024", "type": "type.record.image", "displayDate": "2024-06-01T12:00:00.000Z" } ] }
        """
        let c = """
        { "items": [ { "recordId": "3", "displayName": "2025", "type": "type.record.image", "displayDate": "2025-10-09T08:35:55Z" } ] }
        """
        let fa = FileModel(model: decodeChildren(a)!.items![0], permissions: [.read], accessRole: .viewer)
        let fb = FileModel(model: decodeChildren(b)!.items![0], permissions: [.read], accessRole: .viewer)
        let fc = FileModel(model: decodeChildren(c)!.items![0], permissions: [.read], accessRole: .viewer)
        XCTAssertEqual(vm.sortedByActiveOption([fc, fa, fb]).map { $0.name }, ["2023", "2024", "2025"])
    }

    // MARK: - archiveNo listing gate (G3 — hasBadId bails the whole listing to V1 when a child
    // is missing `archiveNumber`, because retained V1 writes send archiveNbr).

    func testFileModelFromV2_MissingArchiveNumber_YieldsEmptyArchiveNo() {
        // The gate keys on file.archiveNo.isEmpty; a child without `archiveNumber` must
        // surface as empty here so the listing falls back to V1 rather than render items
        // whose later V1 rename/move/edit would send archiveNbr "".
        let missing = """
        { "items": [ { "recordId": "5", "displayName": "no-archive", "type": "type.record.image", "folderLinkId": "9" } ] }
        """
        let present = """
        { "items": [ { "recordId": "5", "displayName": "has-archive", "type": "type.record.image", "folderLinkId": "9", "archiveNumber": "0001-0005" } ] }
        """
        XCTAssertTrue(FileModel(model: decodeChildren(missing)!.items![0], permissions: [.read], accessRole: .viewer).archiveNo.isEmpty)
        XCTAssertFalse(FileModel(model: decodeChildren(present)!.items![0], permissions: [.read], accessRole: .viewer).archiveNo.isEmpty)
    }

    // MARK: - Stela capability matrix — which workspaces follow FeatureFlags.useStelaNavigation
    // Pinned via the in-app FeatureFlags constant (deterministic — no Remote Config dependency);
    // each test restores it in a defer so it can't leak into other tests.

    func testStelaCapability_BaseStaysV1() {
        // The base class hardcodes false: even with the flag forced ON, a bare
        // FilesViewModel (and any subclass that doesn't opt in) must NOT migrate.
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }
        XCTAssertFalse(FilesViewModel().usesStelaNavigation)
    }

    func testStelaCapability_FlagOn_OptedInWorkspacesFollowIt() {
        // My Files, Public Files, Search, Shared drill-in, and the Public Gallery
        // deliberately opt in; the base (and everything inheriting it) stays V1.
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }
        XCTAssertTrue(MyFilesViewModel().usesStelaNavigation)
        XCTAssertTrue(PublicFilesViewModel().usesStelaNavigation)
        XCTAssertTrue(SearchFilesViewModel().usesStelaNavigation)
        XCTAssertTrue(SharedFilesViewModel().usesStelaNavigation)
        XCTAssertTrue(PublicArchiveViewModel().usesStelaNavigation)
        XCTAssertFalse(FilesViewModel().usesStelaNavigation)
    }

    func testStelaCapability_FlagOff_EverythingStaysV1() {
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = false
        defer { FeatureFlags.useStelaNavigation = prevFlag }
        XCTAssertFalse(MyFilesViewModel().usesStelaNavigation)
        XCTAssertFalse(PublicFilesViewModel().usesStelaNavigation)
        XCTAssertFalse(SearchFilesViewModel().usesStelaNavigation)
        XCTAssertFalse(SharedFilesViewModel().usesStelaNavigation)
        XCTAssertFalse(PublicArchiveViewModel().usesStelaNavigation)
        XCTAssertFalse(FilesViewModel().usesStelaNavigation)
    }

    // MARK: - Shared-workspace V2 per-child role inheritance (v2ChildContext)
    // The V2 /children payload carries no per-child accessRole, so Shared inherits the
    // ENTERED folder's role onto its children (confirmed 2026-07-22: a shared folder's own
    // shares[] holds the role, but every child returns shares:[]). Base workspaces keep the
    // archive-level role. Inheritance must fail CLOSED (→ .viewer) so it can never over-grant.

    private func makeV2Folder(role: AccessRole) -> FileModel {
        let json = """
        { "items": [ { "folderId": "10", "displayName": "Shared folder", "type": "private",
          "status": "ok", "folderLinkId": "11", "archiveNumber": "0001-test" } ] }
        """
        return FileModel(model: decodeChildren(json)!.items![0], permissions: [.read], accessRole: role)
    }

    func testV2ChildContext_SharedInheritsEnteredFolderRole_BaseDoesNot() {
        let editorFolder = makeV2Folder(role: .editor)

        // Base (My Files / Public / Search semantics): archive-level role, folder ignored.
        let base = FilesViewModel()
        XCTAssertEqual(base.v2ChildContext(enteredFolder: editorFolder).accessRole, base.archiveAccessRole)
        XCTAssertNotEqual(base.v2ChildContext(enteredFolder: editorFolder).accessRole, .editor,
                          "base must not inherit the folder's role")

        // Shared: children inherit the entered folder's role.
        let shared = SharedFilesViewModel()
        XCTAssertEqual(shared.v2ChildContext(enteredFolder: editorFolder).accessRole, .editor,
                       "shared-folder contents inherit the folder's grant")
    }

    func testV2ChildContext_SharedFailsClosedToViewerWithoutFolder() {
        XCTAssertEqual(SharedFilesViewModel().v2ChildContext(enteredFolder: nil).accessRole, .viewer,
                       "a missing role must fail closed to read-only, never the broader archive role")
    }

    // MARK: - Public Gallery read-only pin (PublicArchiveViewModel)
    // The gallery is a read-only browser, pinned at the ARCHIVE level so every listing path
    // agrees: the V2 `/children` mapping (through the base v2ChildContext), the V1
    // getLeanItems failsafe, and the navigateMin folder push all read archivePermissions /
    // archiveAccessRole. Unlike Shared it must NOT inherit the entered folder's role, and it
    // must NOT use the real archive role — that would hand out write affordances when you
    // browse your OWN archive here, and only on whichever backend served the listing.

    private func decodeArchive(accessRole: String) -> ArchiveVOData? {
        let json = "{\"archiveNbr\":\"0001-test\",\"accessRole\":\"\(accessRole)\",\"fullName\":\"Owned Archive\"}"
        guard let data = json.data(using: .utf8) else { return nil }
        return try? ArchiveVOData.decoder.decode(ArchiveVOData.self, from: data)
    }

    func testV2ChildContext_PublicGalleryPinsViewerRegardlessOfEnteredFolder() throws {
        // The pin is gated on the V2 flag (VSP-1811) and v2ChildContext reads through it, so
        // pin the flag explicitly instead of inheriting the scheme default — otherwise this
        // passes under Permanent-DEV (flag on) and fails under Permanent (flag off).
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }

        let vm = PublicArchiveViewModel()
        // Seed an OWNER archive: with `currentArchive` nil the pin is indistinguishable from
        // the un-pinned base (a nil archive already yields [.read]/.viewer), so every
        // assertion below would pass even with the override deleted.
        vm.currentArchive = try XCTUnwrap(decodeArchive(accessRole: AccessRole.owner.apiValue))
        XCTAssertEqual(AccessRole.roleForValue(vm.currentArchive?.accessRole), .owner,
                       "precondition: the underlying archive really is owner-level")

        for role in [AccessRole.owner, .manager, .curator, .editor, .contributor, .viewer] {
            let context = vm.v2ChildContext(enteredFolder: makeV2Folder(role: role))
            XCTAssertEqual(context.accessRole, .viewer,
                           "public gallery children must stay read-only even inside a \(role) folder")
            XCTAssertEqual(context.permissions, [.read],
                           "public gallery children must carry only .read even inside a \(role) folder")
        }

        // And with no entered folder at all (the root listing).
        XCTAssertEqual(vm.v2ChildContext(enteredFolder: nil).accessRole, .viewer)
        XCTAssertEqual(vm.v2ChildContext(enteredFolder: nil).permissions, [.read])
    }

    func testV2ChildContext_PublicGalleryIgnoresOwnerArchiveRole() throws {
        // Browsing YOUR OWN archive through the gallery: the archive carries the owner
        // role, so an un-pinned gallery would stamp owner permissions onto every child.
        // This is the one case where the pin actually narrows, and it is deliberate.
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }

        let ownerArchive = try XCTUnwrap(decodeArchive(accessRole: AccessRole.owner.apiValue))
        XCTAssertEqual(AccessRole.roleForValue(ownerArchive.accessRole), .owner,
                       "fixture must really be an owner archive, else this test proves nothing")

        let vm = PublicArchiveViewModel()
        vm.currentArchive = ownerArchive
        XCTAssertEqual(vm.currentArchive?.archiveNbr, ownerArchive.archiveNbr,
                       "sanity: the VM did take the owner archive")

        let context = vm.v2ChildContext(enteredFolder: nil)
        XCTAssertEqual(context.accessRole, .viewer, "own archive viewed publicly is still read-only")
        XCTAssertEqual(context.permissions, [.read])
    }

    func testPublicGallery_ArchiveRolePinnedSoTheV1FailsafeCannotDisagree() throws {
        // The pin lives on archivePermissions/archiveAccessRole rather than only on
        // v2ChildContext, because the V1 legs (onGetLeanItemsSuccess / onNavigateMinSuccess)
        // stamp children from these same two properties. Pinning just the V2 leg would let a
        // transient V2 failure hand back write affordances the V2 listing withheld.
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }

        let vm = PublicArchiveViewModel()
        vm.currentArchive = try XCTUnwrap(decodeArchive(accessRole: AccessRole.owner.apiValue))

        XCTAssertEqual(vm.archiveAccessRole, .viewer,
                       "the gallery must never expose the owner role, on either backend")
        XCTAssertEqual(vm.archivePermissions, [.read],
                       "the gallery must never expose write permissions, on either backend")

        // Guard the specific affordances this protects (FilePreviewViewController /
        // FileDetailsViewController share menus, FilePreviewViewModel.isEditable).
        for forbidden in [Permission.edit, .delete, .publish, .share, .ownership, .create, .upload, .move] {
            XCTAssertFalse(vm.archivePermissions.contains(forbidden),
                           "\(forbidden) must not be reachable from the public browser")
        }

        // And the base (non-gallery) behavior is untouched: an owner archive still grants write.
        let base = FilesViewModel()
        XCTAssertTrue(ArchiveVOData.permissions(forAccessRole: AccessRole.owner.apiValue).contains(.edit),
                      "sanity: owner really does imply .edit — else the assertions above are hollow")
        XCTAssertEqual(base.archiveAccessRole, AccessRole.roleForValue(base.currentArchive?.accessRole),
                       "the base class must keep deriving its role from the session archive")
    }

    func testPublicGallery_PinLiftsWhenStelaNavigationIsOff() throws {
        // With V2 navigation OFF there is only one listing path (V1), so the backend-dependent
        // disagreement the pin exists to prevent cannot arise. Keeping the pin would instead
        // strip Share / Publish / editable metadata from your OWN archive in a build that ships
        // with V2 disabled — a regression against what 1.15.x already offers.
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = false
        defer { FeatureFlags.useStelaNavigation = prevFlag }

        let vm = PublicArchiveViewModel()
        vm.currentArchive = try XCTUnwrap(decodeArchive(accessRole: AccessRole.owner.apiValue))

        XCTAssertEqual(vm.archiveAccessRole, .owner,
                       "with V2 nav off the gallery must fall back to the archive's real role")
        XCTAssertTrue(vm.archivePermissions.contains(.edit),
                      "your own archive browsed with V2 nav off keeps its write permissions")

        // Lifting the pin must not over-grant on someone else's archive: a null/unknown
        // accessRole already maps to .viewer, so the foreign case is unchanged either way.
        let foreign = PublicArchiveViewModel()
        foreign.currentArchive = try XCTUnwrap(decodeArchive(accessRole: ""))
        XCTAssertEqual(foreign.archiveAccessRole, .viewer,
                       "a foreign archive must stay read-only even with the pin lifted")
        XCTAssertFalse(foreign.archivePermissions.contains(.edit),
                       "lifting the pin must never grant write on a foreign archive")
    }

    // MARK: - Record rename: V2 PATCH is own-archive only
    // `patchRecord` is sent bearer-only (no share token) and is NOT exempt from the 401
    // force-logout, so attempting it on a FOREIGN (shared-with-me) record risks logging the
    // user out for a rename they were allowed to make. The rename itself would still land via
    // the V1 failsafe — the logout is the damage. Foreign records must never reach the V2 leg.

    // Records are built with `makeV2Record(recordId:archiveId:)`, defined with the VSP-1789
    // copy tests below. It goes through the V2 decode path, which matters here: the
    // convenience `FileModel` init hardcodes `archiveId = -1`, and archiveId is exactly what
    // the ownership check reads.

    /// Runs `body` with the session pinned to `ArchiveVOData.mock()` (archiveID 1).
    private func withSessionArchive(_ body: () -> Void) {
        let previous = AuthenticationManager.shared.session
        let session = PermSession(token: "test_token")
        session.selectedArchive = ArchiveVOData.mock()   // archiveID 1
        AuthenticationManager.shared.session = session
        defer { AuthenticationManager.shared.session = previous }
        body()
    }

    func testIsInSessionArchive_OwnForeignAndIndeterminate() {
        withSessionArchive {
            let vm = FilesViewModel()
            XCTAssertTrue(vm.isInSessionArchive(makeV2Record(archiveId: 1)), "same archive as the session")
            XCTAssertFalse(vm.isInSessionArchive(makeV2Record(archiveId: 2)), "a foreign archive is not ours")
            XCTAssertFalse(vm.isInSessionArchive(makeV2Record(archiveId: -1)),
                           "an absent archiveId is indeterminate and must fail closed")
        }
    }

    func testIsInSessionArchive_NoSession_FailsClosed() {
        let previous = AuthenticationManager.shared.session
        AuthenticationManager.shared.session = nil
        defer { AuthenticationManager.shared.session = previous }

        XCTAssertFalse(FilesViewModel().isInSessionArchive(makeV2Record(archiveId: 1)))
    }

    func testIsInSessionArchive_IgnoresOverriddenCurrentArchive() {
        // `PublicArchiveViewModel` overrides `currentArchive` to the archive being VIEWED.
        // The check must read the SESSION's archive, or browsing a foreign public archive
        // would report its records as "ours".
        withSessionArchive {
            let gallery = PublicArchiveViewModel()
            gallery.currentArchive = ArchiveVOData.mock()   // viewed archive == archiveID 1
            XCTAssertFalse(gallery.isInSessionArchive(makeV2Record(archiveId: 2)),
                           "a foreign record stays foreign even when its archive is the one being viewed")
            XCTAssertTrue(gallery.isInSessionArchive(makeV2Record(archiveId: 1)),
                          "ownership is decided by the session, not by currentArchive")
        }
    }

    func testCanRenameViaStelaPatch_ForeignRecordIsRejected() {
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }

        withSessionArchive {
            // The reported scenario: Shares → "Shared with me" → editor role → Rename.
            let shared = SharedFilesViewModel()
            XCTAssertTrue(shared.usesStelaNavigation, "precondition: Shared opts into the flag")
            XCTAssertFalse(shared.canRenameViaStelaPatch(makeV2Record(archiveId: 2), newName: "new.jpg"),
                           "a shared-with-me record must not reach PATCH /records/{id}")

            // Same record on a base workspace — still foreign, still rejected.
            XCTAssertFalse(MyFilesViewModel().canRenameViaStelaPatch(makeV2Record(archiveId: 2), newName: "new.jpg"))
        }
    }

    func testCanRenameViaStelaPatch_OwnRecordIsAllowed() {
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }

        withSessionArchive {
            XCTAssertTrue(MyFilesViewModel().canRenameViaStelaPatch(makeV2Record(archiveId: 1), newName: "new.jpg"),
                          "own-archive renames must keep using V2 — the gate must not over-tighten")
        }
    }

    func testCanRenameViaStelaPatch_OtherGuardsStillHold() {
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }

        withSessionArchive {
            let vm = MyFilesViewModel()
            let own = makeV2Record(archiveId: 1)

            XCTAssertFalse(vm.canRenameViaStelaPatch(own, newName: ""), "an empty name must not be PATCHed")
            XCTAssertFalse(vm.canRenameViaStelaPatch(makeV2Record(recordId: 0, archiveId: 1), newName: "new.jpg"),
                           "a record with no id must not be PATCHed")
            XCTAssertFalse(vm.canRenameViaStelaPatch(makeV2Folder(role: .owner), newName: "new"),
                           "folder rename has no V2 route")

            FeatureFlags.useStelaNavigation = false
            XCTAssertFalse(vm.canRenameViaStelaPatch(own, newName: "new.jpg"), "flag off means V1")
        }
    }

    /// Observes that `rename` actually consults the gate: a foreign record must reach the V1
    /// leg SYNCHRONOUSLY. The V2 leg is asynchronous, so a synchronous V1 call proves no
    /// PATCH was attempted — and nothing touches the network.
    private final class RenameSpyViewModel: SharedFilesViewModel {
        var v1RenameCallCount = 0
        override func performV1Rename(file: FileModel, name: String?, then handler: @escaping ServerResponse) {
            v1RenameCallCount += 1
            handler(.success)
        }
    }

    func testRename_ForeignRecord_GoesStraightToV1() {
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }

        withSessionArchive {
            let vm = RenameSpyViewModel()
            var status: RequestStatus?
            vm.rename(file: makeV2Record(archiveId: 2), name: "new.jpg") { status = $0 }

            XCTAssertEqual(vm.v1RenameCallCount, 1,
                           "the V1 leg must run synchronously — a V2 attempt would defer it")
            XCTAssertEqual(status, .success)
        }
    }

    // MARK: - Batch PATCH fan-out aggregation (patchSequentially seam)
    // Callers (batch description/location/filename) rely on: `true` ONLY if every record
    // succeeded (a partial-success `true` would skip the V1 batch failsafe and silently
    // drop the remaining edits), short-circuit on first failure, main-thread completion.

    private func makeBatchFile(recordId: Int) -> FileModel {
        // Built via the V2 decode path: the convenience init(name:recordId:...) DISCARDS
        // its recordId parameter (hardcodes -1, FileModel.swift:117), so it cannot build
        // fixtures whose identity matters.
        let json = """
        { "items": [ { "recordId": "\(recordId)", "displayName": "f\(recordId)", "type": "type.record.image",
          "status": "ok", "folderLinkId": "1" } ] }
        """
        return FileModel(model: decodeChildren(json)!.items![0], permissions: [], accessRole: .viewer)
    }

    func testBatchPatch_AllSucceed_SerialInOrder_CompletesTrueOnMain() {
        var patched: [Int] = []
        let exp = expectation(description: "completion")
        Array<FileModel>.patchSequentially(
            files: [makeBatchFile(recordId: 1), makeBatchFile(recordId: 2), makeBatchFile(recordId: 3)],
            fieldsFor: { _ in ["description": "d"] },
            patchOne: { file, fields, done in
                patched.append(file.recordId)
                XCTAssertEqual(fields["description"] as? String, "d")
                done(true)
            },
            completion: { ok in
                XCTAssertTrue(ok)
                XCTAssertTrue(Thread.isMainThread) // callers mutate UI state in the callback
                XCTAssertEqual(patched, [1, 2, 3]) // strictly serial, in order
                exp.fulfill()
            })
        wait(for: [exp], timeout: 2.0)
    }

    func testBatchPatch_FirstFailureShortCircuits_CompletesFalse() {
        var attempts = 0
        let exp = expectation(description: "completion")
        Array<FileModel>.patchSequentially(
            files: [makeBatchFile(recordId: 1), makeBatchFile(recordId: 2), makeBatchFile(recordId: 3)],
            fieldsFor: { _ in [:] },
            patchOne: { file, _, done in
                attempts += 1
                done(file.recordId != 2) // record 2 fails
            },
            completion: { ok in
                XCTAssertFalse(ok)          // false → caller re-runs the V1 batch failsafe
                XCTAssertEqual(attempts, 2) // record 3 never attempted — short-circuit
                exp.fulfill()
            })
        wait(for: [exp], timeout: 2.0)
    }

    // MARK: - V2 item DETAIL adapter (record detail / preview / download)

    private func decodeV2Record(_ json: String) -> RecordV2Data? {
        guard let data = json.data(using: .utf8) else { return nil }
        return (try? RecordV2Response.decoder.decode(RecordV2Response.self, from: data))?.data
    }

    func testRecordV2_MimeTypeDerivation() {
        // V2 carries no contentType — it must be derived from the granular file type.
        XCTAssertEqual(FileV2Data.mimeType(forFileType: "type.file.image.jpeg"), "image/jpeg")
        XCTAssertEqual(FileV2Data.mimeType(forFileType: "type.file.image.jpg"), "image/jpeg")
        XCTAssertEqual(FileV2Data.mimeType(forFileType: "type.file.image.png"), "image/png")
        XCTAssertEqual(FileV2Data.mimeType(forFileType: "type.file.image.heic"), "image/heic")
        XCTAssertEqual(FileV2Data.mimeType(forFileType: "type.file.video.mp4"), "video/mp4")
        XCTAssertEqual(FileV2Data.mimeType(forFileType: "type.file.pdf.pdf"), "application/pdf")
        XCTAssertNil(FileV2Data.mimeType(forFileType: "type.record.image")) // record type, not a file type
        XCTAssertNil(FileV2Data.mimeType(forFileType: nil))
        // Misc/doc/archive classes get a generic MIME: the preview's loadRecord() requires a
        // non-nil contentType in BOTH branches (V1 always ships one; loadMisc only needs
        // presence) — nil here rendered docs/text/zips as a BLANK preview on the V2 path.
        XCTAssertEqual(FileV2Data.mimeType(forFileType: "type.file.doc.docx"), "application/octet-stream")
        XCTAssertEqual(FileV2Data.mimeType(forFileType: "type.file.txt.txt"), "application/octet-stream")
        XCTAssertEqual(FileV2Data.mimeType(forFileType: "type.file.archive.zip"), "application/octet-stream")
    }

    func testRecordV2_AdaptsToRecordVO_ForDetailAndPreview() {
        let json = """
        { "data": {
            "recordId": "8", "displayName": "photo.jpg", "archiveId": "1", "archiveNumber": "0001-test",
            "description": "a pic", "uploadFileName": "IMG_1.HEIC", "size": 1234, "type": "type.record.image",
            "displayDate": "2021-05-01T00:00:00", "createdAt": "2022-01-01T00:00:00", "updatedAt": "2023-01-01T00:00:00",
            "fileCreatedAt": "2020-01-01T00:00:00", "folderLinkId": "9", "parentFolderLinkId": "11",
            "files": [
              { "fileId": "100", "size": 1234, "format": "file.format.converted", "type": "type.file.video.mp4",
                "downloadUrl": "https://cdn/v.mp4", "fileUrl": "https://cdn/f.mp4" }
            ],
            "location": { "latitude": 40.7, "longitude": -74.0, "locality": "NYC", "country": "USA", "streetName": "Main", "streetNumber": "1" },
            "tags": [ { "id": 5, "name": "vacation", "type": "type.generic" } ],
            "thumbUrl200": "https://t/200"
        } }
        """
        let v2 = decodeV2Record(json)!
        // The adapter must yield a RecordVO the existing detail/preview/download code consumes unchanged.
        let recordVO: RecordVO = JSONHelper.decoding(from: v2.toRecordVOPayload(), with: RecordVO.decoder)!
        let record = recordVO.recordVO!
        XCTAssertEqual(record.recordID, 8)              // String -> Int at the boundary
        XCTAssertEqual(record.displayName, "photo.jpg")
        XCTAssertEqual(record.archiveNbr, "0001-test")  // non-numeric -> String passthrough
        XCTAssertEqual(record.recordVODescription, "a pic")
        XCTAssertEqual(record.size, 1234)
        XCTAssertEqual(record.folderLinkID, 9)
        XCTAssertEqual(record.parentFolderLinkID, 11)
        XCTAssertEqual(record.createdDT, "2022-01-01T00:00:00")   // <- createdAt (Uploaded row)
        XCTAssertEqual(record.updatedDT, "2023-01-01T00:00:00")   // <- updatedAt (Last Modified row)
        XCTAssertEqual(record.derivedCreatedDT, "2020-01-01T00:00:00") // <- fileCreatedAt (File Created row)
        XCTAssertNil(record.derivedDT)                  // V2 has no derivedDT -> "Created" row blank (known gap)

        let fileVO = record.fileVOS?.first
        XCTAssertEqual(fileVO?.downloadURL, "https://cdn/v.mp4")
        XCTAssertEqual(fileVO?.format, "file.format.converted")
        XCTAssertEqual(fileVO?.contentType, "video/mp4") // DERIVED from type.file.video.mp4 (V2 omits contentType)

        XCTAssertEqual(record.locnVO?.locality, "NYC")
        XCTAssertEqual(record.locnVO?.latitude, 40.7)
        XCTAssertEqual(record.tagVOS?.first?.name, "vacation")
        // tagId is load-bearing: the batch-metadata screen rebuilds its tag state from
        // these VOs and the V1 unlink body sends tagVO.tagId — a nil here became
        // `tagId: 0` and tag unassign silently no-oped after a V2 record read.
        // REAL WIRE SHAPE (E2E-verified on staging): the key is "id" and it is a JSON
        // NUMBER — decoding the old "tagId"-string contract yielded nil.
        XCTAssertEqual(record.tagVOS?.first?.tagId, 5)
        XCTAssertEqual(record.tagVOS?.first?.type, "type.generic")
    }

    func testRecordV2_TagIdToleratesStringId() {
        // Belt-and-suspenders: if the API ever quotes the id, the decode must still work.
        let json = """
        { "data": { "recordId": "8", "displayName": "x", "type": "type.record.image",
            "tags": [ { "id": "7", "name": "trip", "type": "type.generic" } ] } }
        """
        let v2 = decodeV2Record(json)!
        let recordVO: RecordVO = JSONHelper.decoding(from: v2.toRecordVOPayload(), with: RecordVO.decoder)!
        XCTAssertEqual(recordVO.recordVO?.tagVOS?.first?.tagId, 7)
    }

    func testLocnVO_ToLocationInput_MapsFieldsForV2Patch() {
        let json = """
        { "locality": "NYC", "adminOneName": "NY", "country": "USA", "displayName": "Home",
          "latitude": 40.7128, "longitude": -74.006, "streetNumber": "1", "streetName": "Main St" }
        """
        let locn = try! LocnVO.decoder.decode(LocnVO.self, from: json.data(using: .utf8)!)
        let payload = locn.toLocationInputPayload()
        // LocnVO → Stela LocationInput field names (city/state, sublocation from street).
        XCTAssertEqual(payload["city"] as? String, "NYC")
        XCTAssertEqual(payload["state"] as? String, "NY")
        XCTAssertEqual(payload["country"] as? String, "USA")
        XCTAssertEqual(payload["name"] as? String, "Home")
        XCTAssertEqual(payload["latitude"] as? Double, 40.7128)
        XCTAssertEqual(payload["longitude"] as? Double, -74.006)
        XCTAssertEqual(payload["sublocation"] as? String, "1 Main St")
    }

    // MARK: - Initial State

    func testInit_ViewModelsEmpty() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.viewModels.isEmpty)
    }

    func testInit_NavigationStackEmpty() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.navigationStack.isEmpty)
    }

    func testInit_UploadQueueEmpty() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.uploadQueue.isEmpty)
    }

    func testInit_DownloadQueueEmpty() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.downloadQueue.isEmpty)
    }

    func testInit_UploadInProgressFalse() {
        let vm = FilesViewModel()
        XCTAssertFalse(vm.uploadInProgress)
    }

    func testInit_DownloadInProgressFalse() {
        let vm = FilesViewModel()
        XCTAssertFalse(vm.downloadInProgress)
    }

    func testInit_FileActionIsNone() {
        let vm = FilesViewModel()
        XCTAssertEqual(vm.fileAction, .none)
    }

    func testInit_SelectedFilesEmpty() {
        let vm = FilesViewModel()
        XCTAssertNotNil(vm.selectedFiles)
        XCTAssertTrue(vm.selectedFiles?.isEmpty ?? false)
    }

    func testInit_IsSelectingFalse() {
        let vm = FilesViewModel()
        XCTAssertFalse(vm.isSelecting)
    }

    func testInit_IsSelectingDestinationFalse() {
        let vm = FilesViewModel()
        XCTAssertFalse(vm.isSelectingDestination)
    }

    func testInit_CheckboxStateNone() {
        let vm = FilesViewModel()
        XCTAssertEqual(vm.checkboxState, .none)
    }

    func testInit_ActiveSortOptionDefault() {
        let vm = FilesViewModel()
        XCTAssertEqual(vm.activeSortOption, .nameAscending)
    }

    func testInit_TimerRunCountZero() {
        let vm = FilesViewModel()
        XCTAssertEqual(vm.timerRunCount, 0)
    }

    func testInit_TimerNil() {
        let vm = FilesViewModel()
        XCTAssertNil(vm.timer)
    }

    // MARK: - currentFolder

    func testCurrentFolder_EmptyStack_ReturnsNil() {
        let vm = FilesViewModel()
        XCTAssertNil(vm.currentFolder)
    }

    func testCurrentFolder_WithStack_ReturnsLast() {
        let vm = FilesViewModel()
        let folder = makeFolderFile(name: "Current")
        vm.navigationStack.append(folder)
        XCTAssertEqual(vm.currentFolder?.name, "Current")
    }

    func testCurrentFolder_MultipleInStack_ReturnsLast() {
        let vm = FilesViewModel()
        vm.navigationStack.append(makeFolderFile(name: "First"))
        vm.navigationStack.append(makeFolderFile(name: "Second"))
        XCTAssertEqual(vm.currentFolder?.name, "Second")
    }

    // MARK: - currentFolderIsRoot

    func testCurrentFolderIsRoot_AlwaysTrue() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.currentFolderIsRoot)
    }

    // MARK: - removeCurrentFolderFromHierarchy

    func testRemoveCurrentFolder_EmptyStack_ReturnsNil() {
        let vm = FilesViewModel()
        let result = vm.removeCurrentFolderFromHierarchy()
        XCTAssertNil(result)
    }

    func testRemoveCurrentFolder_WithItems_ReturnsLast() {
        let vm = FilesViewModel()
        let folder = makeFolderFile(name: "ToRemove")
        vm.navigationStack.append(folder)
        let result = vm.removeCurrentFolderFromHierarchy()
        XCTAssertEqual(result?.name, "ToRemove")
        XCTAssertTrue(vm.navigationStack.isEmpty)
    }

    func testRemoveCurrentFolder_LeavesRestOfStack() {
        let vm = FilesViewModel()
        vm.navigationStack.append(makeFolderFile(name: "First"))
        vm.navigationStack.append(makeFolderFile(name: "Second"))
        _ = vm.removeCurrentFolderFromHierarchy()
        XCTAssertEqual(vm.navigationStack.count, 1)
        XCTAssertEqual(vm.navigationStack.first?.name, "First")
    }

    // MARK: - shouldPerformAction

    func testShouldPerformAction_SyncedSection_ReturnsTrue() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.shouldPerformAction(forSection: FileListType.synced.rawValue))
    }

    func testShouldPerformAction_DownloadingSection_ReturnsFalse() {
        let vm = FilesViewModel()
        XCTAssertFalse(vm.shouldPerformAction(forSection: FileListType.downloading.rawValue))
    }

    func testShouldPerformAction_UploadingSection_ReturnsFalse() {
        let vm = FilesViewModel()
        XCTAssertFalse(vm.shouldPerformAction(forSection: FileListType.uploading.rawValue))
    }

    // MARK: - hasCancelButton

    func testHasCancelButton_UploadingSection_ReturnsTrue() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.hasCancelButton(forSection: FileListType.uploading.rawValue))
    }

    func testHasCancelButton_DownloadingSection_ReturnsFalse() {
        let vm = FilesViewModel()
        XCTAssertFalse(vm.hasCancelButton(forSection: FileListType.downloading.rawValue))
    }

    func testHasCancelButton_SyncedSection_ReturnsFalse() {
        let vm = FilesViewModel()
        XCTAssertFalse(vm.hasCancelButton(forSection: FileListType.synced.rawValue))
    }

    // MARK: - title(forSection:)

    func testTitle_DownloadingSection() {
        let vm = FilesViewModel()
        let title = vm.title(forSection: FileListType.downloading.rawValue)
        XCTAssertFalse(title.isEmpty)
    }

    func testTitle_UploadingSection() {
        let vm = FilesViewModel()
        let title = vm.title(forSection: FileListType.uploading.rawValue)
        XCTAssertFalse(title.isEmpty)
    }

    func testTitle_SyncedSection_MatchesSortOptionTitle() {
        let vm = FilesViewModel()
        let title = vm.title(forSection: FileListType.synced.rawValue)
        XCTAssertEqual(title, vm.activeSortOption.title)
    }

    func testTitle_InvalidSection_ReturnsEmpty() {
        let vm = FilesViewModel()
        let title = vm.title(forSection: 99)
        XCTAssertEqual(title, "")
    }

    // MARK: - shouldDisplayBackgroundView

    func testShouldDisplayBackgroundView_EmptyBoth_ReturnsTrue() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.shouldDisplayBackgroundView)
    }

    func testShouldDisplayBackgroundView_HasViewModels_ReturnsFalse() {
        let vm = FilesViewModel()
        vm.viewModels.append(makeRecordFile())
        XCTAssertFalse(vm.shouldDisplayBackgroundView)
    }

    // MARK: - numberOfSections

    func testNumberOfSections_IsThree() {
        let vm = FilesViewModel()
        XCTAssertEqual(vm.numberOfSections, 3)
    }

    // MARK: - numberOfRowsInSection

    func testNumberOfRows_DownloadingSection_MatchesDownloadQueue() {
        let vm = FilesViewModel()
        XCTAssertEqual(vm.numberOfRowsInSection(FileListType.downloading.rawValue), 0)
    }

    func testNumberOfRows_DownloadingSection_WithItems() {
        let vm = FilesViewModel()
        vm.downloadQueue.append(makeRecordFile())
        vm.downloadQueue.append(makeRecordFile())
        XCTAssertEqual(vm.numberOfRowsInSection(FileListType.downloading.rawValue), 2)
    }

    func testNumberOfRows_SyncedSection_MatchesViewModels() {
        let vm = FilesViewModel()
        vm.viewModels.append(makeRecordFile())
        XCTAssertEqual(vm.numberOfRowsInSection(FileListType.synced.rawValue), 1)
    }

    // MARK: - syncedViewModels

    func testSyncedViewModels_EqualsViewModels() {
        let vm = FilesViewModel()
        vm.viewModels.append(makeRecordFile())
        vm.viewModels.append(makeFolderFile())
        XCTAssertEqual(vm.syncedViewModels.count, 2)
    }

    // MARK: - fileForRowAt (synced section)

    func testFileForRowAt_SyncedSection_ReturnsCorrectFile() {
        let vm = FilesViewModel()
        let file = makeRecordFile(name: "test.jpg")
        vm.viewModels.append(file)
        let indexPath = IndexPath(row: 0, section: FileListType.synced.rawValue)
        let result = vm.fileForRowAt(indexPath: indexPath)
        XCTAssertEqual(result.name, "test.jpg")
    }

    func testFileForRowAt_DownloadingSection_ReturnsFromDownloadQueue() {
        let vm = FilesViewModel()
        let file = makeRecordFile(name: "download.jpg")
        vm.downloadQueue.append(file)
        let indexPath = IndexPath(row: 0, section: FileListType.downloading.rawValue)
        let result = vm.fileForRowAt(indexPath: indexPath)
        XCTAssertEqual(result.name, "download.jpg")
    }

    // MARK: - clearDownloadQueue

    func testClearDownloadQueue_RemovesAll() {
        let vm = FilesViewModel()
        vm.downloadQueue.append(makeRecordFile())
        vm.downloadQueue.append(makeRecordFile())
        vm.clearDownloadQueue()
        XCTAssertTrue(vm.downloadQueue.isEmpty)
    }

    // MARK: - removeSyncedFiles

    func testRemoveSyncedFiles_NilFiles_NoChange() {
        let vm = FilesViewModel()
        vm.viewModels.append(makeRecordFile())
        vm.removeSyncedFiles(nil)
        XCTAssertEqual(vm.viewModels.count, 1)
    }

    func testRemoveSyncedFiles_RemovesMatchingFiles() {
        let vm = FilesViewModel()
        let file = makeRecordFile(name: "toRemove.jpg")
        vm.viewModels.append(file)
        vm.removeSyncedFiles([file])
        XCTAssertTrue(vm.viewModels.isEmpty)
    }

    func testRemoveSyncedFiles_EmptyArray_NoChange() {
        let vm = FilesViewModel()
        vm.viewModels.append(makeRecordFile())
        vm.removeSyncedFiles([])
        XCTAssertEqual(vm.viewModels.count, 1)
    }

    // MARK: - updateTimerCount

    func testUpdateTimerCount_IncrementsAcrossBackoffChain() {
        // The thumbnail-poll chain uses exponential-backoff intervals; each
        // fire bumps timerRunCount, and invalidateTimer is only triggered once
        // the chain is exhausted. Confirm increments and the final reset.
        let vm = FilesViewModel()
        XCTAssertEqual(vm.timerRunCount, 0)

        let totalSteps = FilesViewModel.thumbnailPollIntervals.count
        for step in 1..<totalSteps {
            vm.updateTimerCount()
            XCTAssertEqual(vm.timerRunCount, step)
        }

        // Final fire — exhausts the chain and invalidateTimer resets to 0.
        vm.updateTimerCount()
        XCTAssertEqual(vm.timerRunCount, 0)
    }

    // MARK: - invalidateTimer

    func testInvalidateTimer_NilTimer_NoOp() {
        let vm = FilesViewModel()
        vm.invalidateTimer()
        XCTAssertNil(vm.timer)
        XCTAssertEqual(vm.timerRunCount, 0)
    }

    func testInvalidateTimer_WithTimer_SetsNil() {
        let vm = FilesViewModel()
        vm.timer = Timer(timeInterval: 100, repeats: false) { _ in }
        vm.timerRunCount = 5
        vm.invalidateTimer()
        XCTAssertEqual(vm.timerRunCount, 0)
    }

    // MARK: - updateCheckboxState

    func testUpdateCheckboxState_NoSelectedFiles_None() {
        let vm = FilesViewModel()
        vm.selectedFiles = []
        vm.updateCheckboxState()
        XCTAssertEqual(vm.checkboxState, .none)
    }

    func testUpdateCheckboxState_AllSelected_Selected() {
        let vm = FilesViewModel()
        let file = makeRecordFile()
        vm.viewModels = [file]
        vm.selectedFiles = [file]
        vm.updateCheckboxState()
        XCTAssertEqual(vm.checkboxState, .selected)
    }

    func testUpdateCheckboxState_SomeSelected_Partial() {
        let vm = FilesViewModel()
        let file1 = makeRecordFile(name: "a.jpg")
        let file2 = makeRecordFile(name: "b.jpg")
        vm.viewModels = [file1, file2]
        vm.selectedFiles = [file1]
        vm.updateCheckboxState()
        XCTAssertEqual(vm.checkboxState, .partial)
    }

    // MARK: - archivePermissions (no session)

    func testArchivePermissions_NoSession_DefaultsToRead() {
        let vm = FilesViewModel()
        XCTAssertEqual(vm.archivePermissions, [.read])
    }

    // MARK: - archiveAccessRole (no session)

    func testArchiveAccessRole_NoSession_DefaultsToViewer() {
        let vm = FilesViewModel()
        XCTAssertEqual(vm.archiveAccessRole, .viewer)
    }

    // MARK: - relocate edge case

    func testRelocate_NilFiles_ReturnsError() {
        let vm = FilesViewModel()
        let destination = makeFolderFile()
        let expectation = expectation(description: "completion")

        vm.relocate(files: nil, to: destination) { response in
            if case .error = response {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - VSP-1789: Stela V2 copy routing (POST /records/{id}/copies)
    // COPY routes own-archive records through the idempotent V2 endpoint (NO V1 failsafe —
    // copy is not idempotent), while folders, foreign records, and MOVE stay on V1.

    /// `MyFilesViewModel.selectedFiles` proxies the process-wide
    /// `AuthenticationManager.shared.session`, and its setter silently no-ops when that session
    /// is nil. The suite still makes live API calls whose 401s post
    /// `sessionExpiredNotificationName`, which `AuthenticationManager` turns into an async
    /// `logout()` — so the shared session can be nulled mid-test. That is what broke
    /// `testRelocate_Copy_AllEligible_RoutesToV2AndSucceeds` on CI while it passed locally:
    /// `fileAction` (plain storage on the view model) reset correctly, but the selection write
    /// went nowhere. Keeping the selection on the view model makes the assertion about the code
    /// under test instead of about whether a stray logout landed mid-run.
    ///
    /// This does not fix the underlying problem — the unit suite should not reach the network.
    /// Tracked separately; see the repo-hygiene finding about live API calls from tests.
    private final class StelaCopyViewModel: MyFilesViewModel {
        private var localSelection: [FileModel]? = []
        /// Storage only — the production override also posts a selection notification and
        /// refreshes checkbox state, neither of which these tests assert on.
        override var selectedFiles: [FileModel]? {
            get { localSelection }
            set { localSelection = newValue }
        }
    }

    /// A saved record child in the current (mock) archive — the eligible shape for V2 copy.
    /// Built via the V2 decode path (the convenience init discards its recordId, so identity
    /// would be lost). Omitting `folderId` while carrying `recordId` keeps `isFolder` false.
    private func makeV2Record(recordId: Int = 100, archiveId: Int = 1) -> FileModel {
        let json = """
        { "items": [ { "recordId": "\(recordId)", "archiveId": "\(archiveId)", "displayName": "r\(recordId)",
          "type": "type.record.image", "status": "ok", "folderLinkId": "1" } ] }
        """
        return FileModel(model: decodeChildren(json)!.items![0], permissions: [.read], accessRole: .viewer)
    }

    /// Runs `body` with a session whose selected archive is the mock (archiveID 1) and the
    /// Stela flag ON, restoring both afterwards.
    private func withStelaSessionArchive(_ body: () -> Void) {
        let previousSession = AuthenticationManager.shared.session
        let previousFlag = FeatureFlags.useStelaNavigation
        let session = PermSession(token: "test_token")
        session.selectedArchive = ArchiveVOData.mock() // archiveID 1
        AuthenticationManager.shared.session = session
        FeatureFlags.useStelaNavigation = true
        defer {
            AuthenticationManager.shared.session = previousSession
            // Restore what was there, NOT a literal: the ambient value in this build is TRUE
            // (Constants.swift derives it from APIEnvironment == .staging), so restoring false
            // silently changed what every later test saw.
            FeatureFlags.useStelaNavigation = previousFlag
        }
        body()
    }

    func testIsEligibleForStelaCopy_Matrix() {
        withStelaSessionArchive {
            let vm = MyFilesViewModel()
            XCTAssertTrue(vm.isEligibleForStelaCopy(makeV2Record(recordId: 100, archiveId: 1)),
                          "own-archive saved record with the flag on is eligible")
            XCTAssertFalse(vm.isEligibleForStelaCopy(makeV2FolderTarget()),
                           "folders have no V2 copy route")
            XCTAssertFalse(vm.isEligibleForStelaCopy(makeV2Record(recordId: 100, archiveId: 999)),
                           "a foreign-archive record would be rejected on the bearer-only V2 copy")
            XCTAssertFalse(vm.isEligibleForStelaCopy(makeV2Record(recordId: 0, archiveId: 1)),
                           "an unsaved record (recordId 0) is not eligible")
        }
    }

    func testIsEligibleForStelaCopy_FlagOff_False() {
        let previousSession = AuthenticationManager.shared.session
        let session = PermSession(token: "test_token")
        session.selectedArchive = ArchiveVOData.mock()
        AuthenticationManager.shared.session = session
        let previousFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = false
        defer {
            AuthenticationManager.shared.session = previousSession
            FeatureFlags.useStelaNavigation = previousFlag
        }

        XCTAssertFalse(MyFilesViewModel().isEligibleForStelaCopy(makeV2Record()),
                       "flag off keeps every record on V1")
    }

    func testIsEligibleForStelaCopy_BaseViewModelNeverStela() {
        withStelaSessionArchive {
            // Base FilesViewModel returns usesStelaNavigation == false regardless of the flag.
            XCTAssertFalse(FilesViewModel().isEligibleForStelaCopy(makeV2Record()),
                           "workspaces that never opt into Stela keep copy on V1")
        }
    }

    func testRelocate_Copy_AllEligible_RoutesToV2AndSucceeds() {
        withStelaSessionArchive {
            // StelaCopyViewModel, not MyFilesViewModel: this is the one relocate test that
            // asserts the selection was cleared, and MyFilesViewModel routes that through the
            // shared session (see the type's doc comment).
            let vm = StelaCopyViewModel()
            vm.fileAction = .copy
            var copied: [(record: String, destination: String)] = []
            vm.copyRecordV2Request = { recordId, destinationFolderId, completion in
                copied.append((recordId, destinationFolderId))
                completion(true)
            }
            vm.relocateV1Request = { _, _, _ in XCTFail("all files eligible → the V1 batch must not run") }

            let files = [makeV2Record(recordId: 1, archiveId: 1), makeV2Record(recordId: 2, archiveId: 1)]
            let exp = expectation(description: "completion")
            var status: RequestStatus?
            vm.relocate(files: files, to: makeV2FolderTarget(folderId: 10)) { status = $0; exp.fulfill() }
            wait(for: [exp], timeout: 1.0)

            XCTAssertEqual(status, .success)
            XCTAssertEqual(copied.map { $0.record }, ["1", "2"], "each record copied via V2, serially in order")
            XCTAssertEqual(Set(copied.map { $0.destination }), ["10"], "into the destination folderId")
            XCTAssertEqual(vm.fileAction, .none, "the action resets after a copy")
            XCTAssertTrue(vm.selectedFiles?.isEmpty ?? false, "the selection clears after a copy")
        }
    }

    func testRelocate_Copy_V2Failure_ReportsErrorAndNeverFallsBackToV1() {
        withStelaSessionArchive {
            let vm = MyFilesViewModel()
            vm.fileAction = .copy
            var v1Called = false
            vm.copyRecordV2Request = { _, _, completion in completion(false) }
            vm.relocateV1Request = { _, _, completion in v1Called = true; completion(.success) }

            let exp = expectation(description: "completion")
            var status: RequestStatus?
            vm.relocate(files: [makeV2Record(recordId: 1, archiveId: 1)], to: makeV2FolderTarget()) { status = $0; exp.fulfill() }
            wait(for: [exp], timeout: 1.0)

            if case .error = status {} else { XCTFail("a V2 copy failure must surface as an error") }
            XCTAssertFalse(v1Called, "copy is not idempotent — a failed V2 copy must NOT retry on V1")
        }
    }

    func testRelocate_Copy_Mixed_RecordViaV2_FolderViaV1_Aggregates() {
        withStelaSessionArchive {
            let vm = MyFilesViewModel()
            vm.fileAction = .copy
            var v2Records: [String] = []
            var v1Files: [FileModel] = []
            vm.copyRecordV2Request = { recordId, _, completion in v2Records.append(recordId); completion(true) }
            vm.relocateV1Request = { files, _, completion in v1Files = files; completion(.success) }

            let record = makeV2Record(recordId: 7, archiveId: 1)
            let folder = makeV2FolderTarget(folderId: 20)
            let exp = expectation(description: "completion")
            var status: RequestStatus?
            vm.relocate(files: [record, folder], to: makeV2FolderTarget(folderId: 10)) { status = $0; exp.fulfill() }
            wait(for: [exp], timeout: 1.0)

            XCTAssertEqual(status, .success)
            XCTAssertEqual(v2Records, ["7"], "the record is copied via V2")
            XCTAssertEqual(v1Files.map { $0.folderId }, [20], "the folder falls to the V1 batch (no V2 folder-copy route)")
        }
    }

    func testRelocate_Copy_Mixed_V1FolderFails_FailsWholeCopy() {
        withStelaSessionArchive {
            let vm = MyFilesViewModel()
            vm.fileAction = .copy
            vm.copyRecordV2Request = { _, _, completion in completion(true) }
            vm.relocateV1Request = { _, _, completion in completion(.error(message: "boom")) }

            let exp = expectation(description: "completion")
            var status: RequestStatus?
            vm.relocate(files: [makeV2Record(recordId: 7, archiveId: 1), makeV2FolderTarget(folderId: 20)],
                        to: makeV2FolderTarget(folderId: 10)) { status = $0; exp.fulfill() }
            wait(for: [exp], timeout: 1.0)

            if case .error = status {} else { XCTFail("a V1 batch failure must fail the aggregated copy") }
        }
    }

    func testRelocate_Move_NeverUsesStelaV2() {
        withStelaSessionArchive {
            let vm = MyFilesViewModel()
            vm.fileAction = .move
            vm.copyRecordV2Request = { _, _, _ in XCTFail("MOVE must never touch the V2 copy endpoint") }
            var v1Files: [FileModel] = []
            vm.relocateV1Request = { files, _, completion in v1Files = files; completion(.success) }

            let record = makeV2Record(recordId: 7, archiveId: 1) // eligible if it were a copy
            let exp = expectation(description: "completion")
            var status: RequestStatus?
            vm.relocate(files: [record], to: makeV2FolderTarget(folderId: 10)) { status = $0; exp.fulfill() }
            wait(for: [exp], timeout: 1.0)

            XCTAssertEqual(status, .success)
            XCTAssertEqual(v1Files.map { $0.recordId }, [7], "even an own-archive record moves via V1")
        }
    }

    func testRelocate_Copy_MultipleRecords_FirstFails_RestStillAttempted_AggregatesError() {
        withStelaSessionArchive {
            let vm = MyFilesViewModel()
            vm.fileAction = .copy
            var attempted: [String] = []
            vm.copyRecordV2Request = { recordId, _, completion in
                attempted.append(recordId)
                completion(recordId != "1") // the first record fails; the rest succeed
            }
            vm.relocateV1Request = { _, _, _ in XCTFail("all records eligible → the V1 batch must not run") }

            let files = [makeV2Record(recordId: 1, archiveId: 1),
                         makeV2Record(recordId: 2, archiveId: 1),
                         makeV2Record(recordId: 3, archiveId: 1)]
            let exp = expectation(description: "completion")
            var status: RequestStatus?
            vm.relocate(files: files, to: makeV2FolderTarget(folderId: 10)) { status = $0; exp.fulfill() }
            wait(for: [exp], timeout: 1.0)

            XCTAssertEqual(attempted, ["1", "2", "3"],
                           "best-effort: a failed copy must NOT abort the remaining records")
            if case .error = status {} else { XCTFail("any single failure makes the aggregate an error") }
        }
    }

    func testRelocate_Copy_AllIneligible_RoutesToV1Only() {
        withStelaSessionArchive {
            let vm = MyFilesViewModel()
            vm.fileAction = .copy
            vm.copyRecordV2Request = { _, _, _ in XCTFail("no eligible records → V2 must not run") }
            var v1Files: [FileModel] = []
            vm.relocateV1Request = { files, _, completion in v1Files = files; completion(.success) }

            let folders = [makeV2FolderTarget(folderId: 20), makeV2FolderTarget(folderId: 21)]
            let exp = expectation(description: "completion")
            var status: RequestStatus?
            vm.relocate(files: folders, to: makeV2FolderTarget(folderId: 10)) { status = $0; exp.fulfill() }
            wait(for: [exp], timeout: 1.0)

            XCTAssertEqual(status, .success)
            XCTAssertEqual(v1Files.map { $0.folderId }, [20, 21],
                           "an all-folder copy under the flag still falls entirely to the V1 batch")
        }
    }

    func testRelocate_Copy_Mixed_V2RecordFails_V1FolderSucceeds_FailsWholeCopy() {
        withStelaSessionArchive {
            let vm = MyFilesViewModel()
            vm.fileAction = .copy
            vm.copyRecordV2Request = { _, _, completion in completion(false) }
            var v1Ran = false
            vm.relocateV1Request = { _, _, completion in v1Ran = true; completion(.success) }

            let exp = expectation(description: "completion")
            var status: RequestStatus?
            vm.relocate(files: [makeV2Record(recordId: 7, archiveId: 1), makeV2FolderTarget(folderId: 20)],
                        to: makeV2FolderTarget(folderId: 10)) { status = $0; exp.fulfill() }
            wait(for: [exp], timeout: 1.0)

            if case .error = status {} else {
                XCTFail("a failed V2 record must not be masked by a successful V1 folder batch")
            }
            XCTAssertTrue(v1Ran, "the V1 folder batch still runs alongside the failed V2 record")
        }
    }

    // MARK: - VSP-1789: copy thumbnails — HEIC-guarded access-copy 256 as last resort
    // A Stela copy gets NO .thumb.wNNN renditions (backend gap, staging-captured
    // 2026-07-24): thumbUrl* all null; its ONLY thumb is the access-copy
    // thumbnailUrls.256. Non-HEIC listings must fall back to it (else copies are
    // permanent placeholders); HEIC must never use it (blank — white-square bug).

    func testV2CopyShape_ListSlotsFallBackToAccessCopy256_NonHEIC() {
        let json = """
        { "items": [ { "recordId": "89647", "displayName": "frog", "type": "type.record.image",
          "status": "status.generic.ok", "folderLinkId": "137782",
          "uploadFileName": "a-long-frog-3840x2160-green-10125.jpg",
          "thumbUrl200": null, "thumbUrl500": null,
          "thumbnailUrls": { "256": "https://cdn.example/access-256.jpg", "200": null },
          "files": [ { "fileId": "1", "type": "type.file.image.jpg", "format": "file.format.original" } ] } ] }
        """
        let child = decodeChildren(json)!.items![0]

        XCTAssertFalse(child.isHEICOriginal)
        XCTAssertEqual(child.resolvedThumb200, "https://cdn.example/access-256.jpg",
                       "list slot: the access copy is the only thumb a fresh copy has")
        XCTAssertEqual(child.resolvedThumb500, "https://cdn.example/access-256.jpg",
                       "grid slot gets the same last resort")
        XCTAssertNil(child.resolvedThumb256,
                     "the 256/blur slot keeps flat thumbnail256 only — preview behavior unchanged")
    }

    func testV2CopyShape_HEICNeverUsesAccessCopy256() {
        // files[] granular type is the primary signal…
        let byType = """
        { "items": [ { "recordId": "1", "displayName": "heic", "type": "type.record.image",
          "status": "ok", "folderLinkId": "2",
          "thumbnailUrls": { "256": "https://cdn.example/access-256.jpg" },
          "files": [ { "fileId": "1", "type": "type.file.image.heic", "format": "file.format.original" } ] } ] }
        """
        let heicByType = decodeChildren(byType)!.items![0]
        XCTAssertTrue(heicByType.isHEICOriginal)
        XCTAssertNil(heicByType.resolvedThumb200, "a blank HEIC access copy must never be served")

        // …and the filename extension is the fallback when files[] is absent.
        let byName = """
        { "items": [ { "recordId": "1", "displayName": "heic", "type": "type.record.image",
          "status": "ok", "folderLinkId": "2", "uploadFileName": "IMG_0042.HEIC",
          "thumbnailUrls": { "256": "https://cdn.example/access-256.jpg" } } ] }
        """
        let heicByName = decodeChildren(byName)!.items![0]
        XCTAssertTrue(heicByName.isHEICOriginal)
        XCTAssertNil(heicByName.resolvedThumb200)
    }

    func testV2NormalShape_RealRenditionsBeatAccessCopy256() {
        let json = """
        { "items": [ { "recordId": "1", "displayName": "photo", "type": "type.record.image",
          "status": "ok", "folderLinkId": "2", "uploadFileName": "photo.jpg",
          "thumbUrl200": "https://cdn.example/w200.jpg", "thumbUrl500": "https://cdn.example/w500.jpg",
          "thumbnailUrls": { "256": "https://cdn.example/access-256.jpg" },
          "files": [ { "fileId": "1", "type": "type.file.image.jpg", "format": "file.format.original" } ] } ] }
        """
        let child = decodeChildren(json)!.items![0]
        XCTAssertEqual(child.resolvedThumb200, "https://cdn.example/w200.jpg",
                       "real renditions keep priority — no quality change for normal uploads")
        XCTAssertEqual(child.resolvedThumb500, "https://cdn.example/w500.jpg")
    }

    // MARK: - V1 listing thumbnails: the same access-copy trap, a different payload
    // On the V1 payload the `thumbnail256` FIELD is itself the Archivematica access copy
    // (`/access_copies/…/thumbnails/….jpg`), not a real 256 rendition — so preferring it
    // unconditionally served the blank HEIC copy and every HEIC photo in a folder fell back to
    // the file-type placeholder, while `thumbStatus` was "ok" and thumbURL200/500/1000/2000 were
    // all populated right beside it. V2 only met the access copy under `thumbnailUrls.256`, so
    // guarding that left the identically-named V1 field exposed. Production runs V1.
    // `getLeanItems` (the folder listing) decodes ItemVO; record detail decodes RecordVOData.

    func testV1ItemVO_HEICSkipsAccessCopy256AndUsesRealRendition() throws {
        let json = """
        { "uploadFileName": "IMG_1135.heic",
          "thumbnail256": "https://cdn.example/access_copies/blank-for-heic.jpg",
          "thumbURL200": "https://cdn.example/01it-06u7.thumb.w200",
          "thumbURL500": "https://cdn.example/01it-06u7.thumb.w500" }
        """
        let item = try JSONDecoder().decode(ItemVO.self, from: try XCTUnwrap(json.data(using: .utf8)))

        XCTAssertTrue(item.isHEICOriginal)
        XCTAssertEqual(item.preferredThumbnailURL, "https://cdn.example/01it-06u7.thumb.w500",
                       "HEIC must skip the blank access copy and take a real rendition")
    }

    func testV1ItemVO_NonHEICStillPrefersThumbnail256() throws {
        // The guard has to stay narrow: a non-HEIC record must resolve the exact same source it
        // did before, so the fix cannot regress thumbnail size or bandwidth for normal uploads.
        let json = """
        { "uploadFileName": "arctic-fox-4366x3010.jpg",
          "thumbnail256": "https://cdn.example/real-256.jpg",
          "thumbURL500": "https://cdn.example/w500.jpg" }
        """
        let item = try JSONDecoder().decode(ItemVO.self, from: try XCTUnwrap(json.data(using: .utf8)))

        XCTAssertFalse(item.isHEICOriginal)
        XCTAssertEqual(item.preferredThumbnailURL, "https://cdn.example/real-256.jpg",
                       "non-HEIC keeps the 256 — this fix must not touch it")
    }

    func testV1ItemVO_HEICWithNoRenditionsResolvesNil() throws {
        // Fail closed rather than serve a known-blank image: no thumbnail draws the file-type
        // placeholder, whereas a blank one is a white square indistinguishable from a broken file.
        let json = """
        { "uploadFileName": "IMG_9999.HEIF",
          "thumbnail256": "https://cdn.example/access_copies/blank-for-heic.jpg" }
        """
        let item = try JSONDecoder().decode(ItemVO.self, from: try XCTUnwrap(json.data(using: .utf8)))

        XCTAssertTrue(item.isHEICOriginal, ".heif counts too, and the test is case-insensitive")
        XCTAssertNil(item.preferredThumbnailURL)
    }

    func testV1RecordVOData_MirrorsTheItemVOGuard() throws {
        // Record detail decodes RecordVOData, so the guard must exist on both — otherwise the
        // listing is fixed while the preview's blur placeholder still resolves the blank copy.
        let json = """
        { "uploadFileName": "IMG_1135.HEIC",
          "thumbnail256": "https://cdn.example/access_copies/blank-for-heic.jpg",
          "thumbURL500": "https://cdn.example/w500.jpg" }
        """
        let record = try JSONDecoder().decode(RecordVOData.self, from: try XCTUnwrap(json.data(using: .utf8)))

        XCTAssertTrue(record.isHEICOriginal)
        XCTAssertEqual(record.preferredThumbnailURL, "https://cdn.example/w500.jpg")
    }

    func testV1FileModel_PreviewBlurSourceIsHEICGuarded() throws {
        // Guarding only the VO's `preferredThumbnailURL` fixed listings and left the FULL-SCREEN
        // preview broken: `FileModel.preferredThumbnailURL` tries `thumbnailURL256` FIRST, that
        // slot was assigned from the raw field, and it is what the preview blurs behind the
        // full-res load — so HEIC blurred a blank image (the white-square bug). Assert through
        // FileModel, the type the preview actually reads, or the same gap reopens silently.
        let json = """
        { "uploadFileName": "IMG_1135.heic",
          "thumbnail256": "https://cdn.example/access_copies/blank-for-heic.jpg",
          "thumbURL200": "https://cdn.example/w200.jpg",
          "thumbURL500": "https://cdn.example/w500.jpg" }
        """
        let item = try JSONDecoder().decode(ItemVO.self, from: try XCTUnwrap(json.data(using: .utf8)))
        let file = FileModel(model: item, permissions: [.read], accessRole: .viewer)

        XCTAssertNil(file.thumbnailURL256,
                     "the 256 slot must stay empty for HEIC — it is the preview's blur source")
        XCTAssertEqual(file.preferredThumbnailURL, "https://cdn.example/w500.jpg",
                       "the preview must blur a real rendition, never the blank access copy")
    }

    func testV1FileModel_NonHEICKeepsThe256BlurSource() throws {
        // Symmetry check: without this a future "simplification" could null the 256 slot for
        // everything and no test would object, quietly downgrading every preview's placeholder
        // from a 256 thumbnail to a 500 rendition.
        let json = """
        { "uploadFileName": "arctic-fox-4366x3010.jpg",
          "thumbnail256": "https://cdn.example/real-256.jpg",
          "thumbURL500": "https://cdn.example/w500.jpg" }
        """
        let item = try JSONDecoder().decode(ItemVO.self, from: try XCTUnwrap(json.data(using: .utf8)))
        let file = FileModel(model: item, permissions: [.read], accessRole: .viewer)

        XCTAssertEqual(file.thumbnailURL256, "https://cdn.example/real-256.jpg")
        XCTAssertEqual(file.preferredThumbnailURL, "https://cdn.example/real-256.jpg")
    }

    // MARK: - thumbnail poll gate (hasItemsAwaitingProcessing)
    // Gates the 10s post-paste/upload folder poll: keep refetching while a record has
    // no thumbnail source (the fresh-Stela-copy shape) or an item is mid copy/move;
    // stop as soon as everything settles (bounded separately by thumbnailPollMaxRuns).

    func testHasItemsAwaitingProcessing_FreshCopyWithoutThumb_True() {
        let json = """
        { "items": [ { "recordId": "89647", "displayName": "copy", "type": "type.record.image",
          "status": "status.generic.ok", "folderLinkId": "1", "uploadFileName": "copy.heic" } ] }
        """
        let vm = FilesViewModel()
        vm.viewModels = [FileModel(model: decodeChildren(json)!.items![0], permissions: [.read], accessRole: .viewer)]
        XCTAssertTrue(vm.hasItemsAwaitingProcessing,
                      "a record with no thumbnail source is still processing server-side")
    }

    func testHasItemsAwaitingProcessing_SettledRecordAndFolder_False() {
        let json = """
        { "items": [ { "recordId": "1", "displayName": "photo", "type": "type.record.image",
          "status": "ok", "folderLinkId": "2", "thumbUrl200": "https://cdn.example/w200.jpg" },
          { "folderId": "3", "displayName": "folder", "type": "private", "status": "ok", "folderLinkId": "4" } ] }
        """
        let vm = FilesViewModel()
        vm.viewModels = decodeChildren(json)!.items!.map { FileModel(model: $0, permissions: [.read], accessRole: .viewer) }
        XCTAssertFalse(vm.hasItemsAwaitingProcessing,
                       "a thumbed record and a folder are settled — the poll must stop")
    }

    func testHasItemsAwaitingProcessing_CopyingStatus_True() {
        let json = """
        { "items": [ { "folderId": "5", "displayName": "busy", "type": "private",
          "status": "copying", "folderLinkId": "6" } ] }
        """
        let vm = FilesViewModel()
        vm.viewModels = [FileModel(model: decodeChildren(json)!.items![0], permissions: [.read], accessRole: .viewer)]
        XCTAssertTrue(vm.hasItemsAwaitingProcessing, "mid copy/move items keep the poll alive")
    }

    // MARK: - post-paste settle expectation (isAwaitingPastedItems)
    // A relocate commits asynchronously server-side, so the refetch right after a paste can
    // still return the pre-paste listing. hasItemsAwaitingProcessing can't see that (a MOVED
    // record arrives WITH its thumbnails), so the item count is the only usable signal.

    private func makeVMInFolder(itemCount: Int) -> (MyFilesViewModel, FileModel) {
        let vm = MyFilesViewModel()
        let folder = makeV2FolderTarget(folderId: 10)
        vm.navigationStack.append(folder)
        vm.viewModels = (0..<itemCount).map { makeV2Record(recordId: $0 + 1, archiveId: 1) }
        return (vm, folder)
    }

    func testIsAwaitingPastedItems_TrueUntilTheCountArrives() {
        let (vm, folder) = makeVMInFolder(itemCount: 3)
        vm.expectPastedItems([makeV2Record(recordId: 90), makeV2Record(recordId: 91)], destination: folder)

        XCTAssertTrue(vm.isAwaitingPastedItems, "3 listed, 5 expected → still settling")

        vm.viewModels.append(makeV2Record(recordId: 90))
        XCTAssertTrue(vm.isAwaitingPastedItems, "4 of 5 → a partial refetch keeps polling")

        vm.viewModels.append(makeV2Record(recordId: 91))
        XCTAssertFalse(vm.isAwaitingPastedItems, "5 of 5 → landed, chain must stop")
    }

    func testIsAwaitingPastedItems_InertInADifferentFolder() {
        let (vm, folder) = makeVMInFolder(itemCount: 1)
        vm.expectPastedItems([makeV2Record(recordId: 90)], destination: folder)
        XCTAssertTrue(vm.isAwaitingPastedItems)

        vm.navigationStack.append(makeV2FolderTarget(folderId: 99)) // user navigates elsewhere
        XCTAssertFalse(vm.isAwaitingPastedItems,
                       "the expectation is keyed to its folder — it must not poll another folder")
    }

    func testExpectPastedItems_IgnoresEmptyPasteAndForeignDestination() {
        let (vm, folder) = makeVMInFolder(itemCount: 2)

        vm.expectPastedItems([], destination: folder)
        XCTAssertFalse(vm.isAwaitingPastedItems, "nothing pasted → nothing to wait for")

        vm.expectPastedItems([makeV2Record(recordId: 90)], destination: makeV2FolderTarget(folderId: 77))
        XCTAssertFalse(vm.isAwaitingPastedItems, "destination isn't the folder on screen → no expectation")
    }

    func testInvalidateTimer_ClearsThePasteExpectation() {
        let (vm, folder) = makeVMInFolder(itemCount: 1)
        vm.expectPastedItems([makeV2Record(recordId: 90)], destination: folder)
        vm.timer = Timer(timeInterval: 60, repeats: false) { _ in }

        vm.invalidateTimer() // what a manual pull-to-refresh does

        XCTAssertFalse(vm.isAwaitingPastedItems, "a manual pull cancels the chain and its expectation")
        XCTAssertEqual(vm.timerRunCount, 0)
    }

    // MARK: - FAB slide-in contract (FABView.setVisibility)
    // The FAB is hidden while picking a paste destination, which created a hide→show
    // transition that never used to exist. It slides up from the bottom edge; a REPEAT show
    // call (the post-paste folder refetch fires updateFABViewVisibility again a few hundred
    // ms later) must not cut that animation short — that was the "snaps in" symptom.

    /// FAB in a container, so `offscreenSlideDistance` has a superview to measure against.
    private func makeHostedFAB() -> FABView {
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 800))
        let fab = FABView(frame: CGRect(x: 300, y: 700, width: 64, height: 64))
        host.addSubview(fab)
        return fab
    }

    func testFABSetVisibility_ShowFromHiddenSlidesUpFromBelow() {
        let fab = makeHostedFAB()
        fab.setVisibility(hidden: true)
        XCTAssertTrue(fab.isHidden)
        XCTAssertEqual(fab.transform, .identity, "hiding resets the transform so it can't be left off-screen")

        fab.setVisibility(hidden: false)

        XCTAssertFalse(fab.isHidden)
        XCTAssertTrue(fab.isAnimatingIn, "showing from hidden animates")
        XCTAssertGreaterThan(fab.layer.animation(forKey: "transform")?.duration ?? 0, 0,
                             "the slide runs as a real transform animation")
    }

    func testFABSetVisibility_RepeatShowDoesNotRestartOrCutTheSlide() {
        let fab = makeHostedFAB()
        fab.setVisibility(hidden: true)
        fab.setVisibility(hidden: false)
        XCTAssertTrue(fab.isAnimatingIn)

        fab.setVisibility(hidden: false) // what the post-paste refetch triggers

        XCTAssertTrue(fab.isAnimatingIn, "a redundant show must leave the running slide alone")
        XCTAssertFalse(fab.isHidden)
    }

    func testFABSetVisibility_HideStaysSynchronousWhileTheExitAnimates() {
        let fab = makeHostedFAB()
        fab.setVisibility(hidden: true)
        fab.setVisibility(hidden: false)
        XCTAssertTrue(fab.isAnimatingIn)

        // `isHidden` flips at once even though the exit slides a snapshot away — several
        // callers (and MainViewController/SharesViewController tests) read it immediately.
        fab.setVisibility(hidden: true)
        XCTAssertTrue(fab.isHidden)
        XCTAssertFalse(fab.isAnimatingIn)
        XCTAssertEqual(fab.transform, .identity, "the FAB itself is never left translated")
    }

    func testFABSetVisibility_RedundantHideIsANoOp() {
        let fab = makeHostedFAB()
        fab.setVisibility(hidden: true)
        fab.setVisibility(hidden: true) // e.g. updateFABViewVisibility re-asserting paste mode
        XCTAssertTrue(fab.isHidden)
    }

    func testFABSetVisibility_NotAnimatedShowsInstantly() {
        let fab = makeHostedFAB()
        fab.setVisibility(hidden: true)
        fab.setVisibility(hidden: false, animated: false)
        XCTAssertFalse(fab.isHidden)
        XCTAssertFalse(fab.isAnimatingIn)
        XCTAssertEqual(fab.transform, .identity, "no animation → lands in place immediately")
    }

    // MARK: - poll cadence constants
    // Two different waits: missing rows are a server-commit race (fast), pending thumbnails
    // are genuinely slow. Polling a missing row at the slow cadence made a pasted file take
    // ~10s to appear.

    func testPollCadence_FastForMissingRowsSlowForThumbnails() {
        XCTAssertLessThan(FilesViewModel.pastedItemsPollInterval, FilesViewModel.thumbnailPollInterval,
                          "a missing row must be re-checked faster than a pending thumbnail")
        XCTAssertLessThan(FilesViewModel.pastedItemsFastRuns, FilesViewModel.thumbnailPollMaxRuns,
                          "the fast phase is a bounded prefix of the chain, not the whole budget")
    }

    func testPollCadence_TransientStateSitsBetweenTheTwo() {
        // A copying/moving item blocks tapping and clears in seconds-to-tens-of-seconds:
        // faster than the thumbnail settle, gentler than the missing-row race.
        XCTAssertGreaterThan(FilesViewModel.transientStatePollInterval, FilesViewModel.pastedItemsPollInterval)
        XCTAssertLessThan(FilesViewModel.transientStatePollInterval, FilesViewModel.thumbnailPollInterval)
    }

    func testHasItemsInTransientState_DetectsCopyingFolderAndFeedsAwaitingProcessing() {
        // The shape a freshly copied FOLDER arrives in (staging-captured): status "copying",
        // which makes it non-tappable until the server flips it to "ok".
        let json = """
        { "items": [ { "folderId": "49720", "displayName": "22222", "type": "private",
          "status": "copying", "folderLinkId": "137843", "archiveNumber": "01it-06xd" } ] }
        """
        let vm = FilesViewModel()
        vm.viewModels = [FileModel(model: decodeChildren(json)!.items![0], permissions: [.read], accessRole: .viewer)]

        XCTAssertTrue(vm.hasItemsInTransientState, "a copying folder is still settling")
        XCTAssertTrue(vm.hasItemsAwaitingProcessing, "…and therefore keeps the poll alive")
        XCTAssertFalse(vm.viewModels[0].canBeAccessed, "copying items stay non-tappable, as on V1")
    }

    func testHasItemsInTransientState_FalseOnceSettled() {
        let json = """
        { "items": [ { "folderId": "49720", "displayName": "22222", "type": "private",
          "status": "ok", "folderLinkId": "137843", "archiveNumber": "01it-06xd" } ] }
        """
        let vm = FilesViewModel()
        vm.viewModels = [FileModel(model: decodeChildren(json)!.items![0], permissions: [.read], accessRole: .viewer)]

        XCTAssertFalse(vm.hasItemsInTransientState)
        XCTAssertFalse(vm.hasItemsAwaitingProcessing, "a settled folder ends the chain")
    }

    // MARK: - publish edge case

    func testPublish_NoArchive_CompletesWithErrorAndResetsFileAction() {
        // No session → currentArchive (and archiveNbr) is nil, tripping publish's guard.
        // Uses the BASE FilesViewModel because its `fileAction` is a real stored property;
        // MyFilesViewModel's is session-backed and would read `.none` vacuously here.
        let previousSession = AuthenticationManager.shared.session
        AuthenticationManager.shared.session = nil
        defer { AuthenticationManager.shared.session = previousSession }

        let vm = FilesViewModel()
        let exp = expectation(description: "completion")
        var status: RequestStatus?
        vm.publish(files: [makeRecordFile()]) { status = $0; exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        if case .error = status {} else {
            XCTFail("publish must complete with an error when there is no archive (else the caller's spinner hangs)")
        }
        XCTAssertEqual(vm.fileAction, .none, "the guard must reset fileAction so the copy state isn't left stuck")
    }

    // MARK: - delete edge case

    func testDelete_NilFiles_ReturnsError() {
        let vm = FilesViewModel()
        let expectation = expectation(description: "completion")

        vm.delete(nil) { response in
            if case .error = response {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - showMemberChecklist without session

    func testShowMemberChecklist_NoSession_ReturnsNil() {
        let vm = FilesViewModel()
        let expectation = expectation(description: "completion")

        vm.showMemberChecklist { result in
            XCTAssertNil(result)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - queueItemsForCurrentFolder

    func testQueueItemsForCurrentFolder_EmptyQueue_ReturnsEmpty() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.queueItemsForCurrentFolder.isEmpty)
    }

    // MARK: - PublicRootRequestStatus

    func testPublicRootRequestStatus_Equatable() {
        let a = PublicRootRequestStatus.success(folder: nil)
        let b = PublicRootRequestStatus.error(message: "fail")
        XCTAssertEqual(a, b)
    }

    // MARK: - CheckboxState

    func testCheckboxState_AllCases() {
        let none = CheckboxState.none
        let partial = CheckboxState.partial
        let selected = CheckboxState.selected
        XCTAssertNotNil(none)
        XCTAssertNotNil(partial)
        XCTAssertNotNil(selected)
    }

    // MARK: - FileListType

    func testFileListType_RawValues() {
        XCTAssertEqual(FileListType.downloading.rawValue, 0)
        XCTAssertEqual(FileListType.uploading.rawValue, 1)
        XCTAssertEqual(FileListType.synced.rawValue, 2)
    }

    // MARK: - searchViewModels

    func testSearchViewModels_InitiallyEmpty() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.searchViewModels.isEmpty)
    }

    // MARK: - Multiple state changes

    func testNavigationStack_PushAndPop() {
        let vm = FilesViewModel()
        vm.navigationStack.append(makeFolderFile(name: "A"))
        vm.navigationStack.append(makeFolderFile(name: "B"))
        XCTAssertEqual(vm.currentFolder?.name, "B")
        _ = vm.removeCurrentFolderFromHierarchy()
        XCTAssertEqual(vm.currentFolder?.name, "A")
        _ = vm.removeCurrentFolderFromHierarchy()
        XCTAssertNil(vm.currentFolder)
    }

    func testViewModelsManipulation() {
        let vm = FilesViewModel()
        let file1 = makeRecordFile(name: "a")
        let file2 = makeRecordFile(name: "b")
        vm.viewModels = [file1, file2]
        XCTAssertEqual(vm.numberOfRowsInSection(FileListType.synced.rawValue), 2)
        XCTAssertFalse(vm.shouldDisplayBackgroundView)
        vm.viewModels.removeAll()
        XCTAssertTrue(vm.shouldDisplayBackgroundView)
    }

    // MARK: - LocnVO whole-number coordinate decode (VH3-adjacent fix)

    func testLocnVO_WholeNumberCoordinatesDecodeAsDouble() throws {
        // A geocoded coordinate that comes back as a bare integer (40, not 40.0) used to be
        // dropped: JSONAny decodes it as Int and the old Double-only cast returned nil.
        let json = Data(#"{"latitude": 40, "longitude": -74}"#.utf8)
        let locn = try JSONDecoder().decode(LocnVO.self, from: json)
        XCTAssertEqual(locn.latitude, 40.0, "whole-number latitude must bridge Int -> Double")
        XCTAssertEqual(locn.longitude, -74.0, "whole-number longitude must bridge Int -> Double")
    }

    func testLocnVO_DecimalCoordinatesStillDecode() throws {
        let json = Data(#"{"latitude": 37.7602, "longitude": -122.5095}"#.utf8)
        let locn = try JSONDecoder().decode(LocnVO.self, from: json)
        XCTAssertEqual(locn.latitude ?? 0, 37.7602, accuracy: 0.0001)
        XCTAssertEqual(locn.longitude ?? 0, -122.5095, accuracy: 0.0001)
    }

    // MARK: - Camera capture filename uses a 24-hour clock

    func testFileTimestamp_Uses24HourClock() {
        // Build a 1:30:45 PM date in the current calendar/timezone (the same the formatter
        // uses), so the expected string is deterministic on any machine.
        var comps = DateComponents()
        comps.year = 2023; comps.month = 1; comps.day = 2
        comps.hour = 13; comps.minute = 30; comps.second = 45
        let date = Calendar.current.date(from: comps)!
        let stamp = DateUtils.fileTimestampString(for: date)
        XCTAssertEqual(stamp, "20230102-133045",
                       "PM capture must use 24-hour HH (13), not 12-hour hh (01) which collided with AM")
    }

    // MARK: - Record-scoped download-cache name (VH3)

    func testRecordScopedName_PrefixesRecordId() {
        XCTAssertEqual(FileHelper.recordScopedName("photo.jpg", recordId: 88980), "88980/photo.jpg")
    }

    func testRecordScopedName_FallsBackToFlatNameWhenNoRecordId() {
        XCTAssertEqual(FileHelper.recordScopedName("photo.jpg", recordId: 0), "photo.jpg")
        XCTAssertEqual(FileHelper.recordScopedName("photo.jpg", recordId: -1), "photo.jpg")
    }

    // MARK: - V2 navigation supersede policy (childrenFetchV2Request seam)
    // A superseded children fetch must ALWAYS complete its caller (a dropped completion
    // left the tap's spinner hanging — "content doesn't load"), a superseded forward
    // navigation retries exactly once so a racing background refresh can't eat the
    // user's tap, and a superseded fetch must NEVER run the V1 failsafe (its
    // out-of-order response could overwrite the newer listing).

    /// Folder target built via the V2 decode path (folderId > 0 — the convenience
    /// init(name:recordId:...) can't set folderId).
    private func makeV2FolderTarget(folderId: Int = 10) -> FileModel {
        let json = """
        { "items": [ { "folderId": "\(folderId)", "displayName": "Folder \(folderId)", "type": "private",
          "status": "ok", "folderLinkId": "11", "archiveNumber": "0001-test" } ] }
        """
        return FileModel(model: decodeChildren(json)!.items![0], permissions: [.read], accessRole: .viewer)
    }

    /// MyFilesViewModel with the flag pinned ON and the fetch seam scripted to return
    /// `outcomes` in order. Returns the VM and a counter box for fetch invocations.
    private func makeNavVM(outcomes: [FilesViewModel.ChildrenFetchOutcome]) -> (MyFilesViewModel, () -> Int) {
        let vm = MyFilesViewModel()
        var remaining = outcomes
        var fetchCount = 0
        vm.childrenFetchV2Request = { _, completion in
            fetchCount += 1
            completion(remaining.isEmpty ? .failed(message: "unscripted fetch") : remaining.removeFirst())
        }
        return (vm, { fetchCount })
    }

    private var navParams: NavigateMinParams { ("0001-test", 11, nil) }

    func testNavigateV2_Committed_AppendsTargetAndSucceeds() {
        let previousFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = previousFlag }
        let (vm, fetchCount) = makeNavVM(outcomes: [.committed])
        let target = makeV2FolderTarget()
        vm.v2NavigationTarget = target

        var status: RequestStatus?
        vm.navigateMin(params: navParams, backNavigation: false) { status = $0 }

        XCTAssertEqual(status, .success)
        XCTAssertEqual(vm.navigationStack.last, target)
        XCTAssertEqual(fetchCount(), 1)
    }

    func testNavigateV2_ForwardSupersededOnce_RetriesAndWins() {
        let previousFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = previousFlag }
        let (vm, fetchCount) = makeNavVM(outcomes: [.superseded, .committed])
        let target = makeV2FolderTarget()
        vm.v2NavigationTarget = target

        var status: RequestStatus?
        vm.navigateMin(params: navParams, backNavigation: false) { status = $0 }

        XCTAssertEqual(status, .success)
        XCTAssertEqual(fetchCount(), 2, "a superseded tap retries exactly once")
        XCTAssertEqual(vm.navigationStack.map { $0.folderId }, [target.folderId], "target appended once, by the winning retry")
    }

    func testNavigateV2_ForwardSupersededTwice_CompletesQuietlyWithoutNavigating() {
        let previousFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = previousFlag }
        let (vm, fetchCount) = makeNavVM(outcomes: [.superseded, .superseded])
        vm.v2NavigationTarget = makeV2FolderTarget()

        var completions = 0
        vm.navigateMin(params: navParams, backNavigation: false) { _ in completions += 1 }

        XCTAssertEqual(completions, 1, "the caller's completion must fire — a drop leaves its spinner hanging")
        XCTAssertEqual(fetchCount(), 2, "retry is bounded to one")
        XCTAssertTrue(vm.navigationStack.isEmpty, "nothing committed → no navigation")
    }

    func testNavigateV2_BackOrRefreshSuperseded_CompletesQuietlyWithoutRetry() {
        let previousFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = previousFlag }
        let (vm, fetchCount) = makeNavVM(outcomes: [.superseded])
        let current = makeV2FolderTarget()
        vm.navigationStack.append(current)

        var completions = 0
        vm.navigateMin(params: navParams, backNavigation: true) { _ in completions += 1 }

        XCTAssertEqual(completions, 1, "endRefreshing/hideSpinner depend on this completion")
        XCTAssertEqual(fetchCount(), 1, "back/refresh never retries — the superseding fetch repaints this folder")
        XCTAssertEqual(vm.navigationStack.map { $0.folderId }, [current.folderId], "stack untouched")
    }

    // MARK: - VSP-1787: Stela root discovery (archives.rootFolderId → children)
    // Replaces the V1 /folder/getRoot bootstrap. resolveMyFilesTargetV2 is the
    // side-effect-free core (archives → archive-root children → private-root child);
    // any failure returns nil so getRoot falls back to the V1 bootstrap.

    private func decodeArchives(_ json: String) -> [ArchiveV2Data] {
        guard let data = json.data(using: .utf8) else { return [] }
        return (try? ArchivesV2Response.decoder.decode(ArchivesV2Response.self, from: data))?.items ?? []
    }

    /// Archive-root children mirroring the live staging shape: Apps (app-root),
    /// My Files (private-root), Public (public-root). `myFilesFolderId`/`myFilesType`
    /// are parameterized to exercise the id guard and the type/displayName selection.
    private func archiveRootChildrenJSON(myFilesFolderId: String = "600",
                                         myFilesType: String = "private-root",
                                         myFilesDisplayName: String = "My Files") -> String {
        return """
        { "items": [
          { "folderId": "598", "displayName": "Apps", "type": "app-root",
            "status": "ok", "folderLinkId": "701", "archiveNumber": "0001-0002" },
          { "folderId": "\(myFilesFolderId)", "displayName": "\(myFilesDisplayName)", "type": "\(myFilesType)",
            "status": "ok", "folderLinkId": "702", "archiveNumber": "0001-0003" },
          { "folderId": "599", "displayName": "Public", "type": "public-root",
            "status": "ok", "folderLinkId": "703", "archiveNumber": "0001-0004" }
        ] }
        """
    }

    /// MyFilesViewModel with the session's selected archive pinned (archiveNbr "1001",
    /// matching ArchiveVOData.mock()) so `currentArchive` resolves. Restores the previous
    /// session when `body` returns; the injected fetch seams complete synchronously.
    private func withMyFilesVM(_ body: (MyFilesViewModel) -> Void) {
        let previous = AuthenticationManager.shared.session
        let session = PermSession(token: "test_token")
        session.selectedArchive = ArchiveVOData.mock() // archiveNbr "1001"
        AuthenticationManager.shared.session = session
        defer { AuthenticationManager.shared.session = previous }
        body(MyFilesViewModel())
    }

    // --- privateRootChild selection ---

    func testPrivateRootChild_MatchesByType() {
        let children = decodeChildren(archiveRootChildrenJSON())!.items!
        let picked = MyFilesViewModel.privateRootChild(in: children)
        XCTAssertEqual(picked?.folderId, "600", "the private-root child is selected by Stela type")
    }

    func testPrivateRootChild_FallsBackToDisplayName() {
        // type "private" does NOT map to .privateRootFolder, but displayName does match.
        let children = decodeChildren(archiveRootChildrenJSON(myFilesType: "private"))!.items!
        let picked = MyFilesViewModel.privateRootChild(in: children)
        XCTAssertEqual(picked?.folderId, "600", "display-name fallback selects My Files when type doesn't match")
    }

    func testPrivateRootChild_NoneWhenNeitherMatches() {
        let children = decodeChildren(archiveRootChildrenJSON(myFilesType: "private", myFilesDisplayName: "Documents"))!.items!
        XCTAssertNil(MyFilesViewModel.privateRootChild(in: children), "no private-root type and no 'My Files' name → nil")
    }

    // --- resolveMyFilesTargetV2 ---

    func testResolveMyFilesTargetV2_HappyPath_ReturnsMyFilesModel() {
        withMyFilesVM { vm in
            vm.archivesFetchV2Request = { $0(.success(self.decodeArchives(#"{"items":[{"archiveNbr":"1001","rootFolderId":"500","archiveId":"1"}]}"#))) }
            var requestedFolderId: String?
            vm.rootChildrenFetchV2Request = { folderId, completion in
                requestedFolderId = folderId
                completion(.success(self.decodeChildren(self.archiveRootChildrenJSON())!.items!))
            }

            var didComplete = false
            var model: FileModel?
            vm.resolveMyFilesTargetV2 { didComplete = true; model = $0 }

            XCTAssertTrue(didComplete)
            XCTAssertEqual(requestedFolderId, "500", "children are fetched for the matched archive's rootFolderId")
            XCTAssertEqual(model?.folderId, 600, "resolves the private-root My Files folder")
            XCTAssertEqual(model?.type, .privateRootFolder)
            XCTAssertEqual(model?.folderLinkId, 702)
            XCTAssertEqual(model?.archiveNo, "0001-0003", "archiveNo passes through for the V1 navigateMin failsafe")
        }
    }

    func testResolveMyFilesTargetV2_NoSelectedArchive_ReturnsNilWithoutFetching() {
        let previous = AuthenticationManager.shared.session
        AuthenticationManager.shared.session = nil
        defer { AuthenticationManager.shared.session = previous }

        let vm = MyFilesViewModel()
        var archivesFetched = false
        vm.archivesFetchV2Request = { _ in archivesFetched = true }

        var didComplete = false
        var model: FileModel?
        vm.resolveMyFilesTargetV2 { didComplete = true; model = $0 }

        XCTAssertTrue(didComplete, "completion must fire even on the no-archive short-circuit")
        XCTAssertNil(model)
        XCTAssertFalse(archivesFetched, "no current archive → never hits the network")
    }

    func testResolveMyFilesTargetV2_ArchiveNotListed_ReturnsNilWithoutChildrenFetch() {
        withMyFilesVM { vm in
            vm.archivesFetchV2Request = { $0(.success(self.decodeArchives(#"{"items":[{"archiveNbr":"9999","rootFolderId":"500"}]}"#))) }
            var childrenFetched = false
            vm.rootChildrenFetchV2Request = { _, _ in childrenFetched = true }

            var didComplete = false
            var model: FileModel?
            vm.resolveMyFilesTargetV2 { didComplete = true; model = $0 }

            XCTAssertTrue(didComplete)
            XCTAssertNil(model, "the selected archive isn't in the list → nil (caller falls back to V1)")
            XCTAssertFalse(childrenFetched, "no rootFolderId resolved → no children call")
        }
    }

    func testResolveMyFilesTargetV2_ArchivesFetchFails_ReturnsNil() {
        withMyFilesVM { vm in
            vm.archivesFetchV2Request = { $0(.failure(APIError.serverError)) }
            var didComplete = false
            var model: FileModel?
            vm.resolveMyFilesTargetV2 { didComplete = true; model = $0 }
            XCTAssertTrue(didComplete)
            XCTAssertNil(model)
        }
    }

    func testResolveMyFilesTargetV2_RootChildrenFails_ReturnsNil() {
        withMyFilesVM { vm in
            vm.archivesFetchV2Request = { $0(.success(self.decodeArchives(#"{"items":[{"archiveNbr":"1001","rootFolderId":"500"}]}"#))) }
            vm.rootChildrenFetchV2Request = { _, completion in completion(.failure(APIError.serverError)) }
            var didComplete = false
            var model: FileModel?
            vm.resolveMyFilesTargetV2 { didComplete = true; model = $0 }
            XCTAssertTrue(didComplete)
            XCTAssertNil(model)
        }
    }

    func testResolveMyFilesTargetV2_BadFolderId_ReturnsNil() {
        withMyFilesVM { vm in
            vm.archivesFetchV2Request = { $0(.success(self.decodeArchives(#"{"items":[{"archiveNbr":"1001","rootFolderId":"500"}]}"#))) }
            // A private-root child whose folderId resolves to the non-positive sentinel.
            vm.rootChildrenFetchV2Request = { _, completion in
                completion(.success(self.decodeChildren(self.archiveRootChildrenJSON(myFilesFolderId: "0"))!.items!))
            }
            var didComplete = false
            var model: FileModel?
            vm.resolveMyFilesTargetV2 { didComplete = true; model = $0 }
            XCTAssertTrue(didComplete)
            XCTAssertNil(model, "a bad folderId is a contract break → nil, so the caller uses V1")
        }
    }

    // --- getRoot end-to-end (flag ON): resolve → seed → V2 navigate ---

    func testGetRoot_StelaOn_SeedsMyFilesAndNavigatesV2() {
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }
        withMyFilesVM { vm in
            vm.archivesFetchV2Request = { $0(.success(self.decodeArchives(#"{"items":[{"archiveNbr":"1001","rootFolderId":"500"}]}"#))) }
            vm.rootChildrenFetchV2Request = { _, completion in
                completion(.success(self.decodeChildren(self.archiveRootChildrenJSON())!.items!))
            }
            // The final listing (children of My Files) commits via the existing nav seam.
            vm.childrenFetchV2Request = { _, completion in completion(.committed) }

            var status: RequestStatus?
            vm.getRoot { status = $0 }

            XCTAssertEqual(status, .success)
            XCTAssertEqual(vm.navigationStack.last?.folderId, 600, "landed inside the My Files folder via V2")
            XCTAssertNil(vm.v2NavigationTarget, "forward navigation consumes the one-shot target")
        }
    }

    func testGetRoot_StelaOff_RoutesToV1WithoutV2Discovery() {
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = false
        defer { FeatureFlags.useStelaNavigation = prevFlag }
        withMyFilesVM { vm in
            var archivesFetched = false
            var childrenFetched = false
            vm.archivesFetchV2Request = { _ in archivesFetched = true }
            vm.rootChildrenFetchV2Request = { _, _ in childrenFetched = true }

            // Router decision is synchronous; the V1 branch's network call is fire-and-forget
            // and not awaited (we only assert the routing, so this stays non-flaky).
            vm.getRoot { _ in }

            XCTAssertFalse(archivesFetched, "flag OFF must not enter V2 root discovery")
            XCTAssertFalse(childrenFetched, "flag OFF must not enter V2 root discovery")
        }
    }

    // --- Endpoint wire shape (the one request no seam-based test exercises) ---

    func testArchiveV2Endpoint_SearchArchives_URLHeadersAndErrorPolicy() {
        let ep = ArchiveV2Endpoint.searchArchives(
            callerMembershipRoles: ArchiveV2Endpoint.allMembershipRoles,
            pageSize: ArchiveV2Endpoint.defaultPageSize
        )
        let url = ep.customURL ?? ""

        XCTAssertTrue(url.contains("api/v2/archives"), "hits the Stela archives path")
        XCTAssertTrue(url.contains("pageSize=100"))
        // Repeated `callerMembershipRole=<role>` params (NOT a bracketed array or comma-joined),
        // one per role — the form the server's own paginated nextPage emits.
        XCTAssertEqual(url.components(separatedBy: "callerMembershipRole=").count - 1, 6, "one param per role")
        for role in ["owner", "manager", "curator", "editor", "contributor", "viewer"] {
            XCTAssertTrue(url.contains("callerMembershipRole=\(role)"), "missing role \(role)")
        }
        XCTAssertFalse(url.contains("callerMembershipRole[]"), "must not use the bracketed-array form")
        XCTAssertFalse(url.contains("callerMembershipRole%5B%5D"), "must not use the encoded bracketed-array form")

        XCTAssertEqual(ep.method, .get)
        XCTAssertEqual(ep.headers?["Request-Version"], "2")
        XCTAssertTrue(ep.ignoreErrors, "a foreign-archive 401 must fall through to V1, not force-logout")
    }

    func testArchivesV2Response_DecodesVerbatimStagingShape() {
        // Field names + string-typed ids exactly as captured from staging.
        let json = #"""
        {"items":[{"archiveId":"2977","archiveNbr":"01it-0000","name":"test 10115","rootFolderId":"48584","status":"status.generic.ok","type":"type.archive.person","callerMembershipRole":"owner"}],"pagination":{"nextCursor":"2977","nextPage":"...","totalPages":1}}
        """#
        let items = decodeArchives(json)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.archiveNbr, "01it-0000")
        XCTAssertEqual(items.first?.rootFolderId, "48584", "rootFolderId decodes as a String")
        XCTAssertEqual(items.first?.archiveId, "2977")
    }

    // --- selection / resolver gaps flagged by review ---

    func testPrivateRootChild_IgnoresRecordNamedMyFiles() {
        // A RECORD (recordId set, folderId absent) named "My Files" must NOT be selected —
        // it has no folderId and would poison navigateMin with a -1 id.
        let json = #"""
        { "items": [ { "recordId":"700", "displayName":"My Files", "type":"private-root",
          "status":"ok", "folderLinkId":"9", "archiveNumber":"0001-x" } ] }
        """#
        let children = decodeChildren(json)!.items!
        XCTAssertNil(MyFilesViewModel.privateRootChild(in: children), "a record must fail the isFolder guard")
    }

    func testResolveMyFilesTargetV2_MultiArchive_SelectsByArchiveNbrNotPosition() {
        withMyFilesVM { vm in
            // Decoy first (different rootFolderId); the session archive "1001" is second.
            vm.archivesFetchV2Request = {
                $0(.success(self.decodeArchives(#"{"items":[{"archiveNbr":"2002","rootFolderId":"999"},{"archiveNbr":"1001","rootFolderId":"500"}]}"#)))
            }
            var requestedFolderId: String?
            vm.rootChildrenFetchV2Request = { folderId, completion in
                requestedFolderId = folderId
                completion(.success(self.decodeChildren(self.archiveRootChildrenJSON())!.items!))
            }
            var model: FileModel?
            vm.resolveMyFilesTargetV2 { model = $0 }
            XCTAssertEqual(requestedFolderId, "500", "selection is by archiveNbr, not list position")
            XCTAssertEqual(model?.folderId, 600)
        }
    }

    func testResolveMyFilesTargetV2_MatchedArchiveMissingRootFolderId_ReturnsNilWithoutChildrenFetch() {
        withMyFilesVM { vm in
            // Archive matches the session but carries no rootFolderId.
            vm.archivesFetchV2Request = { $0(.success(self.decodeArchives(#"{"items":[{"archiveNbr":"1001"}]}"#))) }
            var childrenFetched = false
            vm.rootChildrenFetchV2Request = { _, _ in childrenFetched = true }
            var didComplete = false
            var model: FileModel?
            vm.resolveMyFilesTargetV2 { didComplete = true; model = $0 }
            XCTAssertTrue(didComplete)
            XCTAssertNil(model, "no rootFolderId → nil (the keystone field the ticket depends on)")
            XCTAssertFalse(childrenFetched, "no rootFolderId resolved → no children call")
        }
    }

    func testResolveMyFilesTargetV2_BadFolderLinkId_ReturnsNil() {
        withMyFilesVM { vm in
            vm.archivesFetchV2Request = { $0(.success(self.decodeArchives(#"{"items":[{"archiveNbr":"1001","rootFolderId":"500"}]}"#))) }
            // Valid folderId but folderLinkId omitted → resolves to the -1 sentinel.
            let json = #"""
            { "items": [ { "folderId":"600", "displayName":"My Files", "type":"private-root",
              "status":"ok", "archiveNumber":"0001-0003" } ] }
            """#
            vm.rootChildrenFetchV2Request = { _, completion in completion(.success(self.decodeChildren(json)!.items!)) }
            var model: FileModel?
            vm.resolveMyFilesTargetV2 { model = $0 }
            XCTAssertNil(model, "a My Files child with a bad folderLinkId (every retained V1 write keys on it) → nil")
        }
    }

    func testResolveMyFilesTargetV2_EmptyArchiveNumber_ReturnsNil() {
        withMyFilesVM { vm in
            vm.archivesFetchV2Request = { $0(.success(self.decodeArchives(#"{"items":[{"archiveNbr":"1001","rootFolderId":"500"}]}"#))) }
            // Valid ids but archiveNumber omitted → archiveNo == "" fails the guard.
            let json = #"""
            { "items": [ { "folderId":"600", "displayName":"My Files", "type":"private-root",
              "status":"ok", "folderLinkId":"702" } ] }
            """#
            vm.rootChildrenFetchV2Request = { _, completion in completion(.success(self.decodeChildren(json)!.items!)) }
            var model: FileModel?
            vm.resolveMyFilesTargetV2 { model = $0 }
            XCTAssertNil(model, "empty archiveNo would break the V1 navigateMin failsafe → nil")
        }
    }

    // MARK: - VSP-1787 follow-up: Public Files root discovery (public-root section)
    // PublicFilesViewModel reuses the same V2 discovery, overriding only the section type
    // (public-root) and the V1 failsafe (getPublicRoot).

    private func withPublicFilesVM(_ body: (PublicFilesViewModel) -> Void) {
        let previous = AuthenticationManager.shared.session
        let session = PermSession(token: "test_token")
        session.selectedArchive = ArchiveVOData.mock() // archiveNbr "1001"
        AuthenticationManager.shared.session = session
        defer { AuthenticationManager.shared.session = previous }
        body(PublicFilesViewModel())
    }

    func testPublicFilesViewModel_RootSectionType_IsPublic() {
        XCTAssertEqual(PublicFilesViewModel().rootSectionType, .publicRootFolder, "Public Files lands in the public root")
        XCTAssertEqual(MyFilesViewModel().rootSectionType, .privateRootFolder, "My Files stays on the private root")
    }

    func testSectionRootChild_SelectsPublicRootByType() {
        let children = decodeChildren(archiveRootChildrenJSON())!.items!
        let picked = MyFilesViewModel.sectionRootChild(in: children, sectionType: .publicRootFolder, fallbackDisplayName: "Public")
        XCTAssertEqual(picked?.folderId, "599", "the public-root child is selected by Stela type")
    }

    func testPublicFilesResolveSectionRootV2_ResolvesPublicRoot() {
        withPublicFilesVM { vm in
            vm.archivesFetchV2Request = { $0(.success(self.decodeArchives(#"{"items":[{"archiveNbr":"1001","rootFolderId":"500"}]}"#))) }
            vm.rootChildrenFetchV2Request = { _, completion in
                completion(.success(self.decodeChildren(self.archiveRootChildrenJSON())!.items!))
            }
            var model: FileModel?
            vm.resolveSectionRootTargetV2(sectionType: vm.rootSectionType, fallbackDisplayName: vm.rootSectionFallbackDisplayName) { model = $0 }
            XCTAssertEqual(model?.folderId, 599, "Public Files resolves the public-root child, not My Files")
            XCTAssertEqual(model?.type, .publicRootFolder)
        }
    }

    func testPublicFiles_getRoot_StelaOn_SeedsPublicRootAndNavigatesV2() {
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }
        withPublicFilesVM { vm in
            vm.archivesFetchV2Request = { $0(.success(self.decodeArchives(#"{"items":[{"archiveNbr":"1001","rootFolderId":"500"}]}"#))) }
            vm.rootChildrenFetchV2Request = { _, completion in
                completion(.success(self.decodeChildren(self.archiveRootChildrenJSON())!.items!))
            }
            vm.childrenFetchV2Request = { _, completion in completion(.committed) }

            var status: RequestStatus?
            vm.getRoot { status = $0 }

            XCTAssertEqual(status, .success)
            XCTAssertEqual(vm.navigationStack.last?.folderId, 599, "landed inside the public root via V2")
            XCTAssertNil(vm.v2NavigationTarget, "forward navigation consumes the one-shot target")
        }
    }
}
