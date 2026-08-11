//
//  FolderInfoCodingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import Foundation
import Testing
@testable import Permanent

/// VSP-1801 added `name`, `itemCount` and `isShared` to `FolderInfo` so the upload Live
/// Activity can draw its destination-folder card. `FolderInfo` is `NSCoding` and is
/// persisted as part of the upload queue, so an archive written by an older build has to
/// keep decoding — and critically, the three new fields have to come back as `nil`, not
/// as `0`/`false`. A `false` there would label a Shared destination "Private", which is a
/// wrong claim about who can see the upload.
///
/// Not `@MainActor` and not serialized: these only touch local archives.
struct FolderInfoCodingTests {

    /// Encodes with `NSKeyedArchiver` and decodes through `init?(coder:)`, which is the
    /// path `PreferencesManager`'s custom-object storage takes for the upload queue.
    private func roundTrip(_ folder: FolderInfo) throws -> FolderInfo {
        let data = try NSKeyedArchiver.archivedData(
            withRootObject: folder,
            requiringSecureCoding: false
        )
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = false
        return try #require(unarchiver.decodeObject(of: FolderInfo.self, forKey: NSKeyedArchiveRootObjectKey))
    }

    // MARK: - Round trip

    @Test("Every field survives an archive round trip")
    func allFieldsRoundTrip() throws {
        let decoded = try roundTrip(
            FolderInfo(
                folderId: 11,
                folderLinkId: 22,
                name: "Northern Lights 2022",
                itemCount: 32,
                isShared: true
            )
        )

        #expect(decoded.folderId == 11)
        #expect(decoded.folderLinkId == 22)
        #expect(decoded.name == "Northern Lights 2022")
        #expect(decoded.itemCount == 32)
        #expect(decoded.isShared == true)
    }

    @Test("isShared false round-trips as false, distinct from unknown")
    func sharedFalseIsNotConfusedWithNil() throws {
        let decoded = try roundTrip(
            FolderInfo(folderId: 1, folderLinkId: 2, name: "Private Files", itemCount: 0, isShared: false)
        )

        #expect(decoded.isShared == false, "A known-Private folder must stay Private")
        #expect(decoded.isShared != nil, "and must not read as unknown")
        #expect(decoded.itemCount == 0, "a real zero count must survive too")
    }

    @Test("Explicit nils round-trip as nils")
    func nilsRoundTrip() throws {
        let decoded = try roundTrip(FolderInfo(folderId: 3, folderLinkId: 4))

        #expect(decoded.folderId == 3)
        #expect(decoded.folderLinkId == 4)
        #expect(decoded.name == nil)
        #expect(decoded.itemCount == nil)
        #expect(decoded.isShared == nil)
    }

    // MARK: - Archives written before the new fields existed

    @Test("An archive with only the original two keys decodes the rest as nil, not 0/false")
    func legacyArchiveDecodesNewFieldsAsNil() throws {
        // Exactly what a queue persisted by the current production build looks like:
        // folderId and folderLinkId, and nothing else.
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        archiver.encode(7, forKey: "folderId")
        archiver.encode(9, forKey: "folderLinkId")
        archiver.finishEncoding()

        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: archiver.encodedData)
        unarchiver.requiresSecureCoding = false
        let decoded = try #require(FolderInfo(coder: unarchiver))

        #expect(decoded.folderId == 7, "the original fields still decode")
        #expect(decoded.folderLinkId == 9)
        #expect(decoded.name == nil, "an absent name must not become an empty string")
        #expect(decoded.itemCount == nil, "an absent count must not become 0")
        #expect(
            decoded.isShared == nil,
            "an absent workspace must not become false — that would label a Shared folder Private"
        )
    }
}
