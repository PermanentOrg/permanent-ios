//
//  ManageTagsViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class ManageTagsViewModelTests: XCTestCase {

    // MARK: - Notification Names

    func testNotificationName_DidUpdateTags() {
        XCTAssertEqual(
            ManageTagsViewModel.didUpdateTagsNotification.rawValue,
            "ManageTagsViewModel.didUpdateTagsNotification"
        )
    }

    func testNotificationName_IsLoading() {
        XCTAssertEqual(
            ManageTagsViewModel.isLoadingNotification.rawValue,
            "ManageTagsViewModel.isLoadingNotification"
        )
    }

    func testNotificationName_IsSearchEnabled() {
        XCTAssertEqual(
            ManageTagsViewModel.isSearchEnabled.rawValue,
            "ManageTagsViewModel.isSearchEnabled"
        )
    }

    func testNotificationName_ShowBanner() {
        XCTAssertEqual(
            ManageTagsViewModel.showBannerNotification.rawValue,
            "ManageTagsViewModel.showBannerNotification"
        )
    }

    func testNotificationName_NoTagsAdded() {
        XCTAssertEqual(
            ManageTagsViewModel.noTagsAdded.rawValue,
            "ManageTagsViewModel.noTagsAdded"
        )
    }

    // MARK: - Initial State

    func testViewModel_InitialState() {
        let vm = ManageTagsViewModel()

        XCTAssertTrue(vm.tags.isEmpty)
        XCTAssertTrue(vm.sortedTags.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.isSearchEnabled)
    }

    // MARK: - isNewTagNameValid

    func testIsNewTagNameValid_NilName() {
        let vm = ManageTagsViewModel()
        XCTAssertFalse(vm.isNewTagNameValid(withText: nil))
    }

    func testIsNewTagNameValid_EmptyName() {
        let vm = ManageTagsViewModel()
        XCTAssertFalse(vm.isNewTagNameValid(withText: ""))
    }

    func testIsNewTagNameValid_ValidNewName() {
        let vm = ManageTagsViewModel()
        XCTAssertTrue(vm.isNewTagNameValid(withText: "Family"))
    }

    // MARK: - searchTags

    func testSearchTags_EmptyText_ResetsSearch() {
        let vm = ManageTagsViewModel()
        vm.isSearchEnabled = true

        vm.searchTags(withText: "")

        XCTAssertFalse(vm.isSearchEnabled)
    }

    // MARK: - Loading Posts Notification

    func testIsLoading_PostsNotification() {
        let vm = ManageTagsViewModel()

        let expectation = XCTNSNotificationExpectation(
            name: ManageTagsViewModel.isLoadingNotification,
            object: vm
        )

        vm.isLoading = true

        wait(for: [expectation], timeout: 1.0)
    }

    func testSortedTags_PostsNotification() {
        let vm = ManageTagsViewModel()

        let expectation = XCTNSNotificationExpectation(
            name: ManageTagsViewModel.didUpdateTagsNotification,
            object: vm
        )

        vm.sortedTags = []

        wait(for: [expectation], timeout: 1.0)
    }
}
