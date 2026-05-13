//
//  ArrayAndSequenceExtensionTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class ArrayAndSequenceExtensionTests: XCTestCase {

    // MARK: - Array prepend

    func testPrepend_ToEmptyArray() {
        var arr: [Int] = []
        arr.prepend(1)
        XCTAssertEqual(arr, [1])
    }

    func testPrepend_ToNonEmptyArray() {
        var arr = [2, 3, 4]
        arr.prepend(1)
        XCTAssertEqual(arr, [1, 2, 3, 4])
    }

    func testPrepend_String() {
        var arr = ["world"]
        arr.prepend("hello")
        XCTAssertEqual(arr, ["hello", "world"])
    }

    // MARK: - Array safeRemoveFirst

    func testSafeRemoveFirst_NonEmptyArray() {
        var arr = [1, 2, 3]
        arr.safeRemoveFirst()
        XCTAssertEqual(arr, [2, 3])
    }

    func testSafeRemoveFirst_SingleElementArray() {
        var arr = [42]
        arr.safeRemoveFirst()
        XCTAssertTrue(arr.isEmpty)
    }

    func testSafeRemoveFirst_EmptyArray() {
        var arr: [Int] = []
        arr.safeRemoveFirst()
        XCTAssertTrue(arr.isEmpty)
    }

    // MARK: - Sequence uniqued

    func testUniqued_NoDuplicates() {
        let arr = [1, 2, 3]
        let result = arr.uniqued()
        XCTAssertEqual(result.count, 3)
    }

    func testUniqued_WithDuplicates() {
        let arr = [1, 2, 2, 3, 3, 3]
        let result = arr.uniqued()
        XCTAssertEqual(result.count, 3)
    }

    func testUniqued_AllSame() {
        let arr = [5, 5, 5]
        let result = arr.uniqued()
        XCTAssertEqual(result, [5])
    }

    func testUniqued_EmptyArray() {
        let arr: [Int] = []
        let result = arr.uniqued()
        XCTAssertTrue(result.isEmpty)
    }

    func testUniqued_Strings() {
        let arr = ["a", "b", "a", "c", "b"]
        let result = arr.uniqued()
        XCTAssertEqual(result.count, 3)
    }

    func testUniqued_PreservesOrder() {
        let arr = [3, 1, 2, 1, 3]
        let result = arr.uniqued()
        XCTAssertEqual(result, [3, 1, 2])
    }

    // MARK: - Sequence asyncMap

    func testAsyncMap_TransformsElements() async throws {
        let arr = [1, 2, 3]
        let result = try await arr.asyncMap { $0 * 2 }
        XCTAssertEqual(result, [2, 4, 6])
    }

    func testAsyncMap_EmptyArray() async throws {
        let arr: [Int] = []
        let result = try await arr.asyncMap { $0 * 2 }
        XCTAssertTrue(result.isEmpty)
    }

    func testAsyncMap_StringTransform() async throws {
        let arr = ["hello", "world"]
        let result = try await arr.asyncMap { $0.uppercased() }
        XCTAssertEqual(result, ["HELLO", "WORLD"])
    }

    // MARK: - DateUtils

    func testDateUtils_CurrentDate_Format() {
        let date = DateUtils.currentDate
        XCTAssertFalse(date.isEmpty)
        XCTAssertTrue(date.contains("."))
        XCTAssertEqual(date.count, 10)
    }

    func testDateUtils_FileTimestamp_Format() {
        let timestamp = DateUtils.fileTimestamp
        XCTAssertFalse(timestamp.isEmpty)
        XCTAssertTrue(timestamp.contains("-"))
    }

    // MARK: - URL init with optional string

    func testURL_InitWithNilString() {
        let url = URL(string: nil as String?)
        XCTAssertNil(url)
    }

    func testURL_InitWithValidString() {
        let url = URL(string: "https://example.com" as String?)
        XCTAssertNotNil(url)
    }
}
