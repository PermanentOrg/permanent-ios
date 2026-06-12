//
//  FolderViewSelectionViewModelTests.swift
//  PermanentTests
//
//  Created by Vlad Alexandru Rusu on 14.10.2022.
//

import XCTest
@testable import Permanent

class FolderViewSelectionViewModelTests: XCTestCase {
    var sut: FolderViewSelectionViewModel!
    let token: String = "token"

    override func setUpWithError() throws {
        let session = PermSession(token: token)
        session.isGridView = false
        sut = FolderViewSelectionViewModel(session: session)
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - Initialization

    func testInit_WithSession_StoresSession() {
        XCTAssertNotNil(sut.session)
    }

    func testInit_IsGridView_DefaultsToSessionValue() {
        XCTAssertFalse(sut.isGridView)
    }

    // MARK: - isGridView Toggle

    func testSetSorting() {
        sut.isGridView = false

        expectation(forNotification: FolderViewSelectionViewModel.didUpdateFolderViewNotification, object: sut) { notification in
            XCTAssertTrue(self.sut.isGridView)
            return true
        }

        sut.isGridView = true

        waitForExpectations(timeout: 5)
    }

    func testIsGridView_SetToFalse_PostsNotification() {
        sut.isGridView = true

        expectation(forNotification: FolderViewSelectionViewModel.didUpdateFolderViewNotification, object: sut) { notification in
            XCTAssertFalse(self.sut.isGridView)
            return true
        }

        sut.isGridView = false

        waitForExpectations(timeout: 5)
    }

    func testIsGridView_SyncsBackToSession() {
        sut.isGridView = true
        XCTAssertTrue(sut.session.isGridView)

        sut.isGridView = false
        XCTAssertFalse(sut.session.isGridView)
    }

    func testIsGridView_ReadsFromSession() {
        sut.session.isGridView = true
        XCTAssertTrue(sut.isGridView)
    }

    // MARK: - Notification

    func testNotificationName_HasExpectedValue() {
        XCTAssertEqual(
            FolderViewSelectionViewModel.didUpdateFolderViewNotification.rawValue,
            "FolderViewSelectionViewModel.didUpdateFolderViewNotification"
        )
    }

    func testNotification_ObjectIsSelf() {
        expectation(forNotification: FolderViewSelectionViewModel.didUpdateFolderViewNotification, object: sut) { notification in
            XCTAssertTrue(notification.object as AnyObject === self.sut)
            return true
        }

        sut.isGridView = true

        waitForExpectations(timeout: 5)
    }

    // MARK: - Multiple Toggles

    func testMultipleToggles_AlwaysPostNotification() {
        var notificationCount = 0

        let observer = NotificationCenter.default.addObserver(
            forName: FolderViewSelectionViewModel.didUpdateFolderViewNotification,
            object: sut,
            queue: nil
        ) { _ in notificationCount += 1 }

        sut.isGridView = true
        sut.isGridView = false
        sut.isGridView = true

        let expectation = expectation(description: "Notifications posted")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)

        XCTAssertEqual(notificationCount, 3)
        NotificationCenter.default.removeObserver(observer)
    }
}
