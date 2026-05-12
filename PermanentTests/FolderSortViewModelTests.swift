//
//  FolderSortViewModelTests.swift
//  PermanentTests
//
//  Created by Vlad Alexandru Rusu on 14.10.2022.
//

import XCTest
@testable import Permanent

final class FolderSortViewModelTests: XCTestCase {

    // MARK: - Initial State

    func testViewModel_DefaultSortOption_IsNameAscending() {
        let sut = FolderSortViewModel()
        XCTAssertEqual(sut.sortingOption, .nameAscending)
    }

    // MARK: - Notification on Change

    func testSetSorting_DateDescending_PostsNotification() {
        let sut = FolderSortViewModel()
        expectation(forNotification: FolderSortViewModel.didUpdateSortingOptionNotification, object: sut) { _ in true }
        sut.sortingOption = .dateDescending
        waitForExpectations(timeout: 5)
        XCTAssertEqual(sut.sortingOption, .dateDescending)
    }

    func testSetSorting_NameDescending_PostsNotification() {
        let sut = FolderSortViewModel()
        expectation(forNotification: FolderSortViewModel.didUpdateSortingOptionNotification, object: sut) { _ in true }
        sut.sortingOption = .nameDescending
        waitForExpectations(timeout: 5)
        XCTAssertEqual(sut.sortingOption, .nameDescending)
    }

    func testSetSorting_DateAscending_PostsNotification() {
        let sut = FolderSortViewModel()
        expectation(forNotification: FolderSortViewModel.didUpdateSortingOptionNotification, object: sut) { _ in true }
        sut.sortingOption = .dateAscending
        waitForExpectations(timeout: 5)
        XCTAssertEqual(sut.sortingOption, .dateAscending)
    }

    func testSetSorting_TypeAscending_PostsNotification() {
        let sut = FolderSortViewModel()
        expectation(forNotification: FolderSortViewModel.didUpdateSortingOptionNotification, object: sut) { _ in true }
        sut.sortingOption = .typeAscending
        waitForExpectations(timeout: 5)
        XCTAssertEqual(sut.sortingOption, .typeAscending)
    }

    func testSetSorting_TypeDescending_PostsNotification() {
        let sut = FolderSortViewModel()
        expectation(forNotification: FolderSortViewModel.didUpdateSortingOptionNotification, object: sut) { _ in true }
        sut.sortingOption = .typeDescending
        waitForExpectations(timeout: 5)
        XCTAssertEqual(sut.sortingOption, .typeDescending)
    }

    // MARK: - Notification Name

    func testNotificationName_HasExpectedValue() {
        XCTAssertEqual(FolderSortViewModel.didUpdateSortingOptionNotification.rawValue, "FolderSortViewModel.didUpdateSortingOptionNotification")
    }

    // MARK: - SortOption Enum

    func testSortOption_AllCasesCount() {
        XCTAssertEqual(SortOption.allCases.count, 6)
    }

    func testSortOption_AllCasesHaveNonEmptyTitle() {
        for option in SortOption.allCases {
            XCTAssertFalse(option.title.isEmpty, "\(option) should have a non-empty title")
        }
    }

    func testSortOption_AllCasesHaveNonEmptyApiValue() {
        for option in SortOption.allCases {
            XCTAssertFalse(option.apiValue.isEmpty, "\(option) should have a non-empty apiValue")
        }
    }

    func testSortOption_ApiValues_AreUnique() {
        let apiValues = SortOption.allCases.map { $0.apiValue }
        XCTAssertEqual(Set(apiValues).count, apiValues.count, "All API values should be unique")
    }

    func testSortOption_RawValues_AreSequential() {
        XCTAssertEqual(SortOption.nameAscending.rawValue, 0)
        XCTAssertEqual(SortOption.nameDescending.rawValue, 1)
        XCTAssertEqual(SortOption.dateAscending.rawValue, 2)
        XCTAssertEqual(SortOption.dateDescending.rawValue, 3)
        XCTAssertEqual(SortOption.typeAscending.rawValue, 4)
        XCTAssertEqual(SortOption.typeDescending.rawValue, 5)
    }
}
