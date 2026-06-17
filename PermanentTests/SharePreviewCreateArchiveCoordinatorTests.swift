//
//  SharePreviewCreateArchiveCoordinatorTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.03.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class SharePreviewCreateArchiveCoordinatorTests: XCTestCase {

    func testPerformCreateArchive_SelectsNewArchiveNotInExistingIDs() async throws {
        let sut = SharePreviewCreateArchiveCoordinator()
        let expected = makeArchive(id: 200, name: "Family")

        var createCalled = false
        var resolveThumbnailCalled = false

        let outcome = try await sut.performCreateArchive(
            name: "Family",
            type: .person,
            existingArchiveIDs: [100],
            createArchiveRequest: { name, type in
                createCalled = true
                XCTAssertEqual(name, "Family")
                XCTAssertEqual(type, ArchiveType.person.rawValue)
            },
            refreshArchives: {
                [self.makeArchive(id: 100, name: "Family"), expected]
            },
            resolveThumbnail: { archive in
                resolveThumbnailCalled = true
                return archive
            }
        )

        XCTAssertTrue(createCalled)
        XCTAssertTrue(resolveThumbnailCalled)
        XCTAssertEqual(outcome.refreshedArchives.count, 2)
        XCTAssertEqual(outcome.selectedArchive?.archiveID, expected.archiveID)
    }

    func testPerformCreateArchive_FallsBackToHighestMatchingArchiveID() async throws {
        let sut = SharePreviewCreateArchiveCoordinator()

        let outcome = try await sut.performCreateArchive(
            name: "Family",
            type: .person,
            existingArchiveIDs: [200, 201],
            createArchiveRequest: { _, _ in },
            refreshArchives: {
                [
                    self.makeArchive(id: 200, name: "Family"),
                    self.makeArchive(id: 201, name: "Family"),
                    self.makeArchive(id: 150, name: "Other")
                ]
            },
            resolveThumbnail: { archive in archive }
        )

        XCTAssertEqual(outcome.selectedArchive?.archiveID, 201)
    }

    func testPerformCreateArchive_NoMatchingArchive_ReturnsNilSelection() async throws {
        let sut = SharePreviewCreateArchiveCoordinator()
        var resolveThumbnailCalled = false

        let outcome = try await sut.performCreateArchive(
            name: "Family",
            type: .person,
            existingArchiveIDs: [],
            createArchiveRequest: { _, _ in },
            refreshArchives: {
                [self.makeArchive(id: 100, name: "Community")]
            },
            resolveThumbnail: { archive in
                resolveThumbnailCalled = true
                return archive
            }
        )

        XCTAssertFalse(resolveThumbnailCalled)
        XCTAssertNil(outcome.selectedArchive)
        XCTAssertEqual(outcome.refreshedArchives.count, 1)
    }

    private func makeArchive(id: Int, name: String) -> ArchiveVOData {
        ArchiveVOData(
            childFolderVOS: nil,
            folderSizeVOS: nil,
            recordVOS: nil,
            accessRole: AccessRole.viewer.apiValue,
            fullName: name,
            spaceTotal: nil,
            spaceLeft: nil,
            fileTotal: nil,
            fileLeft: nil,
            relationType: nil,
            homeCity: nil,
            homeState: nil,
            homeCountry: nil,
            itemVOS: nil,
            birthDay: nil,
            company: nil,
            archiveVODescription: nil,
            archiveID: id,
            publicDT: nil,
            archiveNbr: "\(id)-0000",
            view: nil,
            viewProperty: nil,
            archiveVOPublic: nil,
            vaultKey: nil,
            thumbArchiveNbr: nil,
            type: nil,
            thumbStatus: nil,
            imageRatio: nil,
            thumbnail256: nil,
            thumbURL200: nil,
            thumbURL500: nil,
            thumbURL1000: nil,
            thumbURL2000: nil,
            thumbDT: nil,
            createdDT: nil,
            updatedDT: nil,
            status: .ok
        )
    }
}
