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

    // MARK: - accessedArchiveIDs / setAccessedArchiveIDs

    func testAccessedArchiveIDs_InitialState_IsEmpty() {
        XCTAssertTrue(sut.accessedArchiveIDs.isEmpty)
    }

    func testSetAccessedArchiveIDs_UpdatesPublishedValue() {
        sut.setAccessedArchiveIDs([1, 2, 3])
        XCTAssertEqual(sut.accessedArchiveIDs, [1, 2, 3])
    }

    func testSetAccessedArchiveIDs_ReplacesPreviousSnapshot() {
        sut.setAccessedArchiveIDs([1, 2])
        sut.setAccessedArchiveIDs([7, 8, 9])
        XCTAssertEqual(sut.accessedArchiveIDs, [7, 8, 9])
    }

    func testSetAccessedArchiveIDs_EmptySet_Clears() {
        sut.setAccessedArchiveIDs([1, 2])
        sut.setAccessedArchiveIDs([])
        XCTAssertTrue(sut.accessedArchiveIDs.isEmpty)
    }

    // MARK: - hasAccess

    private func makeArchive(id: Int?, name: String = "Test") -> ShareArchivesFromPastSharesViewModel.PastSharedArchive {
        ShareArchivesFromPastSharesViewModel.PastSharedArchive(
            group: .mine,
            archiveID: id,
            rawName: name,
            title: "The \(name) Archive",
            initials: String(name.prefix(2)).uppercased(),
            thumbnailURL: nil
        )
    }

    func testHasAccess_ReturnsTrueWhenArchiveIDInAccessedSet() {
        sut.setAccessedArchiveIDs([42])
        XCTAssertTrue(sut.hasAccess(makeArchive(id: 42)))
    }

    func testHasAccess_ReturnsFalseWhenArchiveIDNotInAccessedSet() {
        sut.setAccessedArchiveIDs([42])
        XCTAssertFalse(sut.hasAccess(makeArchive(id: 99)))
    }

    func testHasAccess_ReturnsFalseWhenArchiveIDIsNil() {
        sut.setAccessedArchiveIDs([42])
        XCTAssertFalse(sut.hasAccess(makeArchive(id: nil)))
    }

    func testHasAccess_ReturnsFalseWhenAccessedSetIsEmpty() {
        XCTAssertFalse(sut.hasAccess(makeArchive(id: 42)))
    }

    // MARK: - accessedLast Ordering

    func testAccessedLast_EmptyList_ReturnsEmpty() {
        XCTAssertTrue(sut.accessedLast([]).isEmpty)
    }

    func testAccessedLast_NoneAccessed_PreservesOrder() {
        let a = makeArchive(id: 1, name: "Alpha")
        let b = makeArchive(id: 2, name: "Bravo")
        let c = makeArchive(id: 3, name: "Charlie")
        sut.setAccessedArchiveIDs([])

        let result = sut.accessedLast([a, b, c])

        XCTAssertEqual(result.map { $0.archiveID }, [1, 2, 3])
    }

    func testAccessedLast_AllAccessed_PreservesOrder() {
        let a = makeArchive(id: 1, name: "Alpha")
        let b = makeArchive(id: 2, name: "Bravo")
        sut.setAccessedArchiveIDs([1, 2])

        let result = sut.accessedLast([a, b])

        XCTAssertEqual(result.map { $0.archiveID }, [1, 2])
    }

    func testAccessedLast_MixedAccessed_MovesAccessedToEnd() {
        let a = makeArchive(id: 1, name: "Alpha")
        let b = makeArchive(id: 2, name: "Bravo")
        let c = makeArchive(id: 3, name: "Charlie")
        let d = makeArchive(id: 4, name: "Delta")
        sut.setAccessedArchiveIDs([2, 3])

        let result = sut.accessedLast([a, b, c, d])

        XCTAssertEqual(result.map { $0.archiveID }, [1, 4, 2, 3])
    }

    func testAccessedLast_PreservesAlphabeticalWithinGroups() {
        let alpha = makeArchive(id: 1, name: "Alpha")
        let bravo = makeArchive(id: 2, name: "Bravo")
        let charlie = makeArchive(id: 3, name: "Charlie")
        let delta = makeArchive(id: 4, name: "Delta")
        sut.setAccessedArchiveIDs([1, 3])

        let result = sut.accessedLast([alpha, bravo, charlie, delta])

        XCTAssertEqual(result.map { $0.rawName }, ["Bravo", "Delta", "Alpha", "Charlie"])
    }

    func testAccessedLast_NilArchiveID_TreatedAsNotAccessed() {
        let nilID = makeArchive(id: nil, name: "NoID")
        let accessed = makeArchive(id: 1, name: "Accessed")
        sut.setAccessedArchiveIDs([1])

        let result = sut.accessedLast([nilID, accessed])

        XCTAssertEqual(result.map { $0.rawName }, ["NoID", "Accessed"])
    }
}
