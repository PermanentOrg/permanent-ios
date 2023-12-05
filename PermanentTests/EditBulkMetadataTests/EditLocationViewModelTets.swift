//
//  EditLocationViewModelTets.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 20.09.2023.

import Foundation
import XCTest
import Combine
@testable import Permanent

class EditLocationViewModelTests: XCTestCase {

    var sut: AddLocationViewModel!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        sut = AddLocationViewModel(selectedFiles: [], commonLocation: nil)
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        cancellables = nil
        super.tearDown()
    }

    func testGoogleSearchLocation() {
        sut.debouncedText = "Test Location"
        XCTAssertNotNil(sut.searchedLocations)
    }

    func testUpdate() {
        let expectation = XCTestExpectation(description: "Update completes")
        sut.update { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testGetDistance() {
        let distance = sut.getDistance(from: NSNumber(value: 1000))
        XCTAssertEqual(distance, "0.6 miles")
    }
}

