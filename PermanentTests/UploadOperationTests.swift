//
//  UploadOperationTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class UploadOperationTests: XCTestCase {

    // MARK: - UploadError

    func testUploadError_ConformsToError() {
        let errors: [UploadError] = [.presignedURL, .s3, .registerRecord]
        XCTAssertEqual(errors.count, 3)
        let descriptions = Set(errors.map { $0.localizedDescription })
        XCTAssertEqual(descriptions.count, 3, "Each error should have a unique description")
    }

    // MARK: - Notification Names

    func testNotificationNames_HaveExpectedValues() {
        XCTAssertEqual(UploadOperation.uploadProgressNotification.rawValue, "UploadOperation.uploadProgressNotification")
        XCTAssertEqual(UploadOperation.uploadFinishedNotification.rawValue, "UploadOperation.uploadFinishedNotification")
        XCTAssertEqual(UploadOperation.registerRecordTimingNotification.rawValue, "UploadOperation.registerRecordTimingNotification")
    }

    func testNotificationNames_AreAllUnique() {
        let names: Set = [
            UploadOperation.uploadProgressNotification,
            UploadOperation.uploadFinishedNotification,
            UploadOperation.registerRecordTimingNotification
        ]
        XCTAssertEqual(names.count, 3)
    }

    // MARK: - UploadError Descriptions

    func testUploadError_PresignedURL_HasDescription() {
        let error = UploadError.presignedURL
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }

    func testUploadError_S3_HasDescription() {
        let error = UploadError.s3
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }

    func testUploadError_RegisterRecord_HasDescription() {
        let error = UploadError.registerRecord
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }

    func testUploadError_AllCases_HaveDistinctDescriptions() {
        let errors: [UploadError] = [.presignedURL, .s3, .registerRecord]
        let descriptions = Set(errors.map { $0.localizedDescription })
        XCTAssertEqual(descriptions.count, 3)
    }

    // MARK: - UploadError Conformance

    func testUploadError_CanBeUsedAsErrorProtocol() {
        let error: Error = UploadError.presignedURL
        XCTAssertNotNil(error)
    }

    func testUploadError_CanBeCastToNSError() {
        let error = UploadError.s3 as NSError
        XCTAssertNotNil(error.domain)
    }

    func testUploadError_EqualitySameCase() {
        let error1 = UploadError.presignedURL
        let error2 = UploadError.presignedURL
        XCTAssertTrue(error1.localizedDescription == error2.localizedDescription)
    }

    func testUploadError_DifferentCases_NotEqual() {
        let error1 = UploadError.presignedURL
        let error2 = UploadError.s3
        XCTAssertNotEqual(error1.localizedDescription, error2.localizedDescription)
    }
}
