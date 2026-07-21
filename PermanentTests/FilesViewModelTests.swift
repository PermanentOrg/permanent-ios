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
        // The base class hardcodes false: even with the flag forced ON, generic
        // listings (Shared workspace etc.) must NOT migrate.
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = false }
        XCTAssertFalse(FilesViewModel().usesStelaNavigation)
    }

    func testStelaCapability_FlagOn_OptedInWorkspacesFollowIt() {
        // My Files, Public Files, and Search drill-in deliberately opt in;
        // the base (and everything inheriting it) stays V1.
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = false }
        XCTAssertTrue(MyFilesViewModel().usesStelaNavigation)
        XCTAssertTrue(PublicFilesViewModel().usesStelaNavigation)
        XCTAssertTrue(SearchFilesViewModel().usesStelaNavigation)
        XCTAssertFalse(FilesViewModel().usesStelaNavigation)
    }

    func testStelaCapability_FlagOff_EverythingStaysV1() {
        FeatureFlags.useStelaNavigation = false
        XCTAssertFalse(MyFilesViewModel().usesStelaNavigation)
        XCTAssertFalse(PublicFilesViewModel().usesStelaNavigation)
        XCTAssertFalse(SearchFilesViewModel().usesStelaNavigation)
        XCTAssertFalse(FilesViewModel().usesStelaNavigation)
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
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = false }
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
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = false }
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
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = false }
        let (vm, fetchCount) = makeNavVM(outcomes: [.superseded, .superseded])
        vm.v2NavigationTarget = makeV2FolderTarget()

        var completions = 0
        vm.navigateMin(params: navParams, backNavigation: false) { _ in completions += 1 }

        XCTAssertEqual(completions, 1, "the caller's completion must fire — a drop leaves its spinner hanging")
        XCTAssertEqual(fetchCount(), 2, "retry is bounded to one")
        XCTAssertTrue(vm.navigationStack.isEmpty, "nothing committed → no navigation")
    }

    func testNavigateV2_BackOrRefreshSuperseded_CompletesQuietlyWithoutRetry() {
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = false }
        let (vm, fetchCount) = makeNavVM(outcomes: [.superseded])
        let current = makeV2FolderTarget()
        vm.navigationStack.append(current)

        var completions = 0
        vm.navigateMin(params: navParams, backNavigation: true) { _ in completions += 1 }

        XCTAssertEqual(completions, 1, "endRefreshing/hideSpinner depend on this completion")
        XCTAssertEqual(fetchCount(), 1, "back/refresh never retries — the superseding fetch repaints this folder")
        XCTAssertEqual(vm.navigationStack.map { $0.folderId }, [current.folderId], "stack untouched")
    }
}
