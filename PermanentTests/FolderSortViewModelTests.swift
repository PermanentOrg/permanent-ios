//
//  FolderSortViewModelTests.swift
//  PermanentTests
//
//  Created by Vlad Alexandru Rusu on 14.10.2022.
//

import XCTest
@testable import Permanent

class FolderSortViewModelTests: XCTestCase {
    var sut: FolderSortViewModel!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSetSorting() {
        sut = FolderSortViewModel()
        
        expectation(forNotification: FolderSortViewModel.didUpdateSortingOptionNotification, object: sut) { notification in
            XCTAssertEqual(self.sut.sortingOption, .dateDescending)
            return true
        }
        
        sut.sortingOption = .dateDescending
        
        waitForExpectations(timeout: 5)
    }
}
