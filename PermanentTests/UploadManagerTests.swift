//
//  UploadManagerTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class UploadManagerTests: XCTestCase {

    // MARK: - Singleton

    func testSharedInstance_IsSameReference() {
        let first = UploadManager.shared
        let second = UploadManager.shared
        XCTAssertTrue(first === second)
    }

    // MARK: - Queue State

    func testUploadQueue_Exists() {
        let manager = UploadManager.shared
        XCTAssertNotNil(manager.uploadQueue)
    }

    func testQueuedFiles_EmptyInitially() {
        let manager = UploadManager.shared
        manager.cancelAll()

        let queued = manager.queuedFiles()
        XCTAssertTrue(queued.isEmpty)
    }

    func testInProgressUpload_NilWhenIdle() {
        let manager = UploadManager.shared
        manager.cancelAll()

        let inProgress = manager.inProgressUpload()
        XCTAssertNil(inProgress)
    }

    // MARK: - Queue Configuration

    func testUploadQueue_DefaultMaxConcurrency() {
        let manager = UploadManager.shared
        XCTAssertGreaterThanOrEqual(manager.uploadQueue.maxConcurrentOperationCount, 1)
    }

    func testUploadQueue_OperationCountWhenIdle() {
        let manager = UploadManager.shared
        manager.cancelAll()
        XCTAssertEqual(manager.uploadQueue.operationCount, 0)
    }

    // MARK: - Notifications

    func testNotificationNames_AreUnique() {
        let names: Set = [
            UploadManager.didRefreshQueueNotification,
            UploadManager.didUploadFileNotification,
            UploadManager.quotaExceededNotification,
            UploadManager.didCreateMobileUploadsFolderNotification
        ]
        XCTAssertEqual(names.count, 4, "Each notification name should be unique")
    }

    func testDidRefreshQueueNotification_HasExpectedName() {
        XCTAssertEqual(UploadManager.didRefreshQueueNotification.rawValue, "UploadManager.didRefreshQueueNotification")
    }

    func testDidUploadFileNotification_HasExpectedName() {
        XCTAssertEqual(UploadManager.didUploadFileNotification.rawValue, "UploadManager.didUploadFileNotification")
    }

    func testQuotaExceededNotification_HasExpectedName() {
        XCTAssertEqual(UploadManager.quotaExceededNotification.rawValue, "UploadManager.quotaExceededNotification")
    }

    func testDidCreateMobileUploadsFolderNotification_HasExpectedName() {
        XCTAssertEqual(UploadManager.didCreateMobileUploadsFolderNotification.rawValue, "UploadManager.didCreateMobileUploadsFolderNotification")
    }

    // MARK: - Timer

    func testTimer_Exists() {
        let manager = UploadManager.shared
        XCTAssertNotNil(manager.timer)
    }

    // MARK: - Cancel All

    func testCancelAll_ClearsQueue() {
        let manager = UploadManager.shared
        manager.cancelAll()

        XCTAssertTrue(manager.queuedFiles().isEmpty)
        XCTAssertNil(manager.inProgressUpload())
    }
}
