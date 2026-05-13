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
}
