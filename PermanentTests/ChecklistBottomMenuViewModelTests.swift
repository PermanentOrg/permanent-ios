//
//  ChecklistBottomMenuViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class ChecklistBottomMenuViewModelTests: XCTestCase {

    // MARK: - Init

    func testInit_ShowsChecklistButton_True() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        XCTAssertTrue(sut.showsChecklistButton)
    }

    func testInit_ShowsChecklistButton_False() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: false)
        XCTAssertFalse(sut.showsChecklistButton)
    }

    func testInit_IsLoadingIsFalse() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        XCTAssertFalse(sut.isLoading)
    }

    func testInit_ShowErrorIsFalse() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        XCTAssertFalse(sut.showError)
    }

    func testInit_ListCompletedIsFalse() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        XCTAssertFalse(sut.listCompleted)
    }

    // MARK: - completionPercentage

    func testCompletionPercentage_EmptyItems_ReturnsZero() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        sut.items = []
        XCTAssertEqual(sut.completionPercentage, 0)
    }

    func testCompletionPercentage_AllCompleted_Returns100() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        sut.items = [
            ChecklistItem(type: .archiveCreated, completed: true),
            ChecklistItem(type: .firstUpload, completed: true),
            ChecklistItem(type: .storageRedeemed, completed: true)
        ]
        XCTAssertEqual(sut.completionPercentage, 100)
    }

    func testCompletionPercentage_NoneCompleted_ReturnsZero() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        sut.items = [
            ChecklistItem(type: .archiveCreated, completed: false),
            ChecklistItem(type: .firstUpload, completed: false)
        ]
        XCTAssertEqual(sut.completionPercentage, 0)
    }

    func testCompletionPercentage_HalfCompleted_Returns50() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        sut.items = [
            ChecklistItem(type: .archiveCreated, completed: true),
            ChecklistItem(type: .firstUpload, completed: false)
        ]
        XCTAssertEqual(sut.completionPercentage, 50)
    }

    func testCompletionPercentage_OneOfThree_Returns33() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        sut.items = [
            ChecklistItem(type: .archiveCreated, completed: true),
            ChecklistItem(type: .firstUpload, completed: false),
            ChecklistItem(type: .storageRedeemed, completed: false)
        ]
        XCTAssertEqual(sut.completionPercentage, 33)
    }

    func testCompletionPercentage_TwoOfThree_Returns66() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        sut.items = [
            ChecklistItem(type: .archiveCreated, completed: true),
            ChecklistItem(type: .firstUpload, completed: true),
            ChecklistItem(type: .storageRedeemed, completed: false)
        ]
        XCTAssertEqual(sut.completionPercentage, 66)
    }

    func testCompletionPercentage_SingleCompleted_Returns100() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        sut.items = [
            ChecklistItem(type: .archiveCreated, completed: true)
        ]
        XCTAssertEqual(sut.completionPercentage, 100)
    }

    func testCompletionPercentage_SingleNotCompleted_ReturnsZero() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        sut.items = [
            ChecklistItem(type: .archiveCreated, completed: false)
        ]
        XCTAssertEqual(sut.completionPercentage, 0)
    }

    // MARK: - changeChecklistContent

    func testChangeChecklistContent_SetsViewState() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        sut.changeChecklistContent(.content)
        XCTAssertEqual(sut.viewState, .content)
    }

    func testChangeChecklistContent_ToDontShowAgain() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        sut.changeChecklistContent(.dontShowAgain)
        XCTAssertEqual(sut.viewState, .dontShowAgain)
    }

    func testChangeChecklistContent_ToCongrats() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        sut.changeChecklistContent(.congrats)
        XCTAssertEqual(sut.viewState, .congrats)
    }

    func testChangeChecklistContent_ToError() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        sut.changeChecklistContent(.error)
        XCTAssertEqual(sut.viewState, .error)
    }

    func testChangeChecklistContent_ToLoading() {
        let sut = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        sut.changeChecklistContent(.content)
        sut.changeChecklistContent(.loading)
        XCTAssertEqual(sut.viewState, .loading)
    }

    // MARK: - ChecklistItem

    func testChecklistItem_InitWithType_SetsCorrectId() {
        let item = ChecklistItem(type: .archiveCreated)
        XCTAssertEqual(item.id, "archiveCreated")
        XCTAssertFalse(item.completed)
    }

    func testChecklistItem_InitWithCompleted_SetsCompletedTrue() {
        let item = ChecklistItem(type: .firstUpload, completed: true)
        XCTAssertTrue(item.completed)
    }

    func testChecklistItem_TypeProperty_ReturnsCorrectType() {
        let item = ChecklistItem(type: .storageRedeemed)
        XCTAssertEqual(item.type, .storageRedeemed)
    }

    func testChecklistItem_TitleIsNonEmpty() {
        let item = ChecklistItem(type: .archiveCreated)
        XCTAssertFalse(item.title.isEmpty)
    }

    // MARK: - ChecklistItemType

    func testChecklistItemType_AllCasesHaveTitles() {
        let types: [ChecklistItemType] = [
            .archiveCreated, .storageRedeemed, .legacyContact,
            .archiveSteward, .archiveProfile, .firstUpload, .publishContent
        ]
        for type in types {
            XCTAssertFalse(type.title.isEmpty, "\(type) should have a non-empty title")
        }
    }

    func testChecklistItemType_RawValues() {
        XCTAssertEqual(ChecklistItemType.archiveCreated.rawValue, "archiveCreated")
        XCTAssertEqual(ChecklistItemType.storageRedeemed.rawValue, "storageRedeemed")
        XCTAssertEqual(ChecklistItemType.legacyContact.rawValue, "legacyContact")
        XCTAssertEqual(ChecklistItemType.archiveSteward.rawValue, "archiveSteward")
        XCTAssertEqual(ChecklistItemType.archiveProfile.rawValue, "archiveProfile")
        XCTAssertEqual(ChecklistItemType.firstUpload.rawValue, "firstUpload")
        XCTAssertEqual(ChecklistItemType.publishContent.rawValue, "publishContent")
    }

    // MARK: - ChecklistViewState

    func testChecklistViewState_AllCasesExist() {
        let states: [ChecklistViewState] = [.loading, .content, .dontShowAgain, .congrats, .error]
        XCTAssertEqual(states.count, 5)
    }
}
