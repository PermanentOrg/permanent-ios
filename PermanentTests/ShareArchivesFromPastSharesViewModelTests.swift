//
//  ShareArchivesFromPastSharesViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 08.05.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class ShareArchivesFromPastSharesViewModelTests: XCTestCase {
    private var sut: ShareArchivesFromPastSharesViewModel!

    override func setUp() {
        super.setUp()
        sut = ShareArchivesFromPastSharesViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState_SearchTextIsEmpty() {
        XCTAssertEqual(sut.searchText, "")
    }

    func testInitialState_MyArchivesListIsEmpty() {
        XCTAssertTrue(sut.myArchivesList.isEmpty)
    }

    func testInitialState_OtherArchivesListIsEmpty() {
        XCTAssertTrue(sut.otherArchivesList.isEmpty)
    }

    func testInitialState_IsLoadingIsFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_MyArchivesIsEmpty() {
        XCTAssertTrue(sut.myArchives.isEmpty)
    }

    func testInitialState_OtherArchivesIsEmpty() {
        XCTAssertTrue(sut.otherArchives.isEmpty)
    }

    // MARK: - Title

    func testTitle_ReturnsExpectedString() {
        XCTAssertEqual(sut.title, "Select archive from past shares")
    }

    // MARK: - PastSharedArchive Struct

    func testPastSharedArchive_HasUniqueIds() {
        let a = ShareArchivesFromPastSharesViewModel.PastSharedArchive(
            group: .mine, archiveID: 1, rawName: "Test", title: "The Test Archive", initials: "TE", thumbnailURL: nil
        )
        let b = ShareArchivesFromPastSharesViewModel.PastSharedArchive(
            group: .mine, archiveID: 1, rawName: "Test", title: "The Test Archive", initials: "TE", thumbnailURL: nil
        )
        XCTAssertNotEqual(a.id, b.id)
    }

    func testPastSharedArchive_StoresAllProperties() {
        let archive = ShareArchivesFromPastSharesViewModel.PastSharedArchive(
            group: .other, archiveID: 42, rawName: "John Doe", title: "The John Doe Archive", initials: "JD", thumbnailURL: "https://example.com/thumb.jpg"
        )
        XCTAssertEqual(archive.archiveID, 42)
        XCTAssertEqual(archive.rawName, "John Doe")
        XCTAssertEqual(archive.title, "The John Doe Archive")
        XCTAssertEqual(archive.initials, "JD")
        XCTAssertEqual(archive.thumbnailURL, "https://example.com/thumb.jpg")
    }

    func testPastSharedArchive_MineGroup() {
        let archive = ShareArchivesFromPastSharesViewModel.PastSharedArchive(
            group: .mine, archiveID: 1, rawName: "A", title: "A", initials: "A", thumbnailURL: nil
        )
        if case .mine = archive.group {} else {
            XCTFail("Expected .mine group")
        }
    }

    func testPastSharedArchive_OtherGroup() {
        let archive = ShareArchivesFromPastSharesViewModel.PastSharedArchive(
            group: .other, archiveID: 1, rawName: "A", title: "A", initials: "A", thumbnailURL: nil
        )
        if case .other = archive.group {} else {
            XCTFail("Expected .other group")
        }
    }

    func testPastSharedArchive_NilArchiveID() {
        let archive = ShareArchivesFromPastSharesViewModel.PastSharedArchive(
            group: .mine, archiveID: nil, rawName: "X", title: "X", initials: "X", thumbnailURL: nil
        )
        XCTAssertNil(archive.archiveID)
    }

    func testPastSharedArchive_NilThumbnailURL() {
        let archive = ShareArchivesFromPastSharesViewModel.PastSharedArchive(
            group: .other, archiveID: 5, rawName: "Y", title: "Y", initials: "Y", thumbnailURL: nil
        )
        XCTAssertNil(archive.thumbnailURL)
    }

    // MARK: - Computed Properties With Empty Lists

    func testMyArchives_EmptyList_WithSearchText_ReturnsEmpty() {
        sut.searchText = "anything"
        XCTAssertTrue(sut.myArchives.isEmpty)
    }

    func testOtherArchives_EmptyList_WithSearchText_ReturnsEmpty() {
        sut.searchText = "anything"
        XCTAssertTrue(sut.otherArchives.isEmpty)
    }

    func testMyArchives_EmptyList_WithEmptySearch_ReturnsEmpty() {
        sut.searchText = ""
        XCTAssertTrue(sut.myArchives.isEmpty)
    }

    func testOtherArchives_EmptyList_WithEmptySearch_ReturnsEmpty() {
        sut.searchText = ""
        XCTAssertTrue(sut.otherArchives.isEmpty)
    }

    // MARK: - SearchText Behavior

    func testSearchText_CanBeSet() {
        sut.searchText = "test query"
        XCTAssertEqual(sut.searchText, "test query")
    }

    func testSearchText_CanBeCleared() {
        sut.searchText = "test query"
        sut.searchText = ""
        XCTAssertEqual(sut.searchText, "")
    }

    func testSearchText_WhitespaceOnlyDoesNotCrash() {
        sut.searchText = "   "
        XCTAssertTrue(sut.myArchives.isEmpty)
        XCTAssertTrue(sut.otherArchives.isEmpty)
    }

    func testSearchText_SpecialCharactersDoNotCrash() {
        sut.searchText = "tom & jerry"
        XCTAssertTrue(sut.myArchives.isEmpty)
    }

    func testSearchText_UnicodeDoesNotCrash() {
        sut.searchText = "café résumé"
        XCTAssertTrue(sut.myArchives.isEmpty)
    }
}
