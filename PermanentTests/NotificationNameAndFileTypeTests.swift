//
//  NotificationNameAndFileTypeTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class NotificationNameAndFileTypeTests: XCTestCase {

    // MARK: - Notification Names

    func testNotificationNames_HaveExpectedValues() {
        XCTAssertEqual(Notification.Name.filePreviewVMDidSaveData.rawValue, "filePreviewVMDidSaveData")
        XCTAssertEqual(Notification.Name.filePreviewVMSaveDataFailed.rawValue, "filePreviewVMSaveDataFailed")
        XCTAssertEqual(Notification.Name.publicProfilePageUpdate.rawValue, "publicProfilePageUpdate")
    }

    // MARK: - FileType isFolder

    func testFileType_IsFolder_FolderTypes() {
        let folderTypes: [FileType] = [.publicFolder, .privateFolder, .publicRootFolder, .privateRootFolder, .sharedFolder]
        for type in folderTypes {
            XCTAssertTrue(type.isFolder, "\(type.rawValue) should be a folder")
        }
    }

    func testFileType_IsFolder_NonFolderTypes() {
        let nonFolderTypes: [FileType] = [.image, .video, .audio, .pdf, .miscellaneous]
        for type in nonFolderTypes {
            XCTAssertFalse(type.isFolder, "\(type.rawValue) should not be a folder")
        }
    }

    // MARK: - FileType Codable

    func testFileType_RoundTrip_Codable() throws {
        let original = FileType.video
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FileType.self, from: encoded)
        XCTAssertEqual(decoded, original)
    }

    func testFileType_DecodableFromRawValue() throws {
        let jsonData = try XCTUnwrap("\"type.record.video\"".data(using: .utf8))
        let decoded = try JSONDecoder().decode(FileType.self, from: jsonData)
        XCTAssertEqual(decoded, .video)
    }

    // MARK: - FileType.fromV2 (Stela V2 `type` strings)
    // The V2 /folders/{id}/children payload serializes FOLDER types as a pretty string
    // ("public", "private-root", …) that does NOT match FileType's raw values, while
    // RECORDS keep the legacy "type.record.*" raw string. Getting this wrong silently
    // turns a folder into a record: `didSelectItemAt` keys the drill-in vs open-preview
    // decision on `file.type.isFolder`, so a mis-mapped folder would open the file
    // preview instead of navigating into it.

    func testFromV2_FolderTypes_MapToFolderCases() {
        // "public" is the Public Gallery's case — the gallery is the first screen whose
        // V2 children come back public rather than private (verified against staging).
        let cases: [(String, FileType)] = [
            ("public", .publicFolder),
            ("public-root", .publicRootFolder),
            ("public_root", .publicRootFolder),
            ("private", .privateFolder),
            ("private-root", .privateRootFolder),
            ("private_root", .privateRootFolder),
            ("share", .sharedFolder),
            ("share-root", .sharedFolder),
            ("share_root", .sharedFolder)
        ]

        for (raw, expected) in cases {
            let mapped = FileType.fromV2(typeString: raw, isFolder: true)
            XCTAssertEqual(mapped, expected, "V2 folder type \"\(raw)\" must map to \(expected.rawValue)")
            XCTAssertTrue(mapped.isFolder, "V2 folder type \"\(raw)\" must stay tappable as a folder")
        }
    }

    func testFromV2_UnknownFolderType_FallsBackToAFolder() {
        // An unrecognized folder type must still be a FOLDER. Falling back to a record
        // case would make the item open a file preview that can never load.
        for raw in ["something-new", "", "type.folder.public"] {
            let mapped = FileType.fromV2(typeString: raw, isFolder: true)
            XCTAssertTrue(mapped.isFolder, "unknown V2 folder type \"\(raw)\" must still be a folder")
        }
        XCTAssertTrue(FileType.fromV2(typeString: nil, isFolder: true).isFolder)
    }

    func testFromV2_RecordTypes_KeepLegacyRawValues() {
        let cases: [(String, FileType)] = [
            ("type.record.image", .image),
            ("type.record.video", .video),
            ("type.record.audio", .audio),
            ("type.record.pdf", .pdf),
            ("type.record.misc", .miscellaneous)
        ]

        for (raw, expected) in cases {
            let mapped = FileType.fromV2(typeString: raw, isFolder: false)
            XCTAssertEqual(mapped, expected, "V2 record type \"\(raw)\" must decode from its raw value")
            XCTAssertFalse(mapped.isFolder, "V2 record type \"\(raw)\" must not be treated as a folder")
        }
    }

    func testFromV2_UnknownRecordType_FallsBackToMiscellaneous() {
        for raw in ["type.record.brand.new", "public", ""] {
            let mapped = FileType.fromV2(typeString: raw, isFolder: false)
            XCTAssertEqual(mapped, .miscellaneous, "unknown V2 record type \"\(raw)\" must degrade to .miscellaneous")
            XCTAssertFalse(mapped.isFolder)
        }
        XCTAssertEqual(FileType.fromV2(typeString: nil, isFolder: false), .miscellaneous)
    }
}
