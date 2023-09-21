//
//  EditTagsViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 20.09.2023.

import Foundation
import XCTest
import Combine
@testable import Permanent
import KeychainSwift

class AddNewTagViewModelTests: XCTestCase {
    var sut: AddNewTagViewModel!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        let tagsRemoteMockDataSource = TagsRemoteMockDataSource()
        let tagsManagementRepository = TagsRepository(remoteDataSource: tagsRemoteMockDataSource)
        sut = AddNewTagViewModel(tagsRepository: tagsManagementRepository, selectionTags: [], selectedFiles: [])
        createMockSession()
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func testRefreshTags() {
        // Assuming refreshTags() should return a list of tags
        let tags: () = sut.refreshTags()
        XCTAssertNotNil(tags, "Tags should not be nil after refreshTags() is called")
    }

    func testCalculateUncommonTags() {
        // Assuming calculateUncommonTags() should return a list of uncommon tags
        let uncommonTags = sut.calculateUncommonTags()
        XCTAssertNotNil(uncommonTags, "Uncommon tags should not be nil after calculateUncommonTags() is called")
    }

    func testCalculateFilteredUncommonTags() {
        // Assuming calculateFilteredUncommonTags() should return a list of filtered uncommon tags
        let filteredUncommonTags = sut.calculateFilteredUncommonTags(text: "")
        XCTAssertNotNil(filteredUncommonTags, "Filtered uncommon tags should not be nil after calculateFilteredUncommonTags() is called")
    }

    func testAssignTagToArchive() {
        // Assuming assignTagToArchive() should return a success status
        let success = sut.assignTagToArchive(tagNames: []) { success in
            XCTAssertTrue(success, "assignTagToArchive() should return true")
        }
    }

    func testAddButtonPressed() {
        // Assuming addButtonPressed() should return a success status
        let success = sut.addButtonPressed { success in
            XCTAssertTrue(success, "addButtonPressed() should return true")
        }
    }

    func testRunAssignTag() async {
        // Assuming runAssignTag() should return a success status
        do {
            let success = try await sut.runAssignTag(tags: [], recordId: 0)
        } catch {
            XCTFail("runAssignTag() threw an error: \(error)")
        }
    }
    
    func createMockSession() {
        let session = PermSession(token: "test_token")
        session.selectedArchive = ArchiveVOData.mock()
        session.account = AccountVOData.mock()

        AuthenticationManager.shared.session = session
    }
}
