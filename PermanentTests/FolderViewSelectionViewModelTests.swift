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
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSetSorting() {
        let session = PermSession(token: token)
        session.isGridView = false
        
        sut = FolderViewSelectionViewModel(session: session)
        sut.isGridView = false
        
        expectation(forNotification: FolderViewSelectionViewModel.didUpdateFolderViewNotification, object: sut) { notification in
            XCTAssertTrue(self.sut.isGridView)
            return true
        }
        
        sut.isGridView = true
        
        waitForExpectations(timeout: 5)
    }
}
