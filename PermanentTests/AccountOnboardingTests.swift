//
//  AccountOnboardingTests.swift
//  PermanentTests
//
//  Created by Vlad Alexandru Rusu on 16.06.2022.
//

import XCTest

@testable import Permanent

class AccountOnboardingTests: XCTestCase {
    var sut: AccountOnboardingViewModel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        sut = AccountOnboardingViewModel()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        
        try super.tearDownWithError()
    }
    
    func testArchiveNameNotification() throws {
        let expectation = XCTestExpectation()
        
        NotificationCenter.default.addObserver(forName: AccountOnboardingViewModel.archiveNameChanged, object: sut, queue: nil) { notification in
            XCTAssertTrue(self.sut.archiveName == "Test")
            expectation.fulfill()
        }
        
        sut.archiveName = "Test"
    }
    
    func testArchiveTypeNotification() throws {
        let expectation = XCTestExpectation()
        
        NotificationCenter.default.addObserver(forName: AccountOnboardingViewModel.archiveTypeChanged, object: sut, queue: nil) { notification in
            XCTAssertTrue(self.sut.archiveType == .family)
            expectation.fulfill()
        }
        
        sut.archiveType = .family
    }
    
    func testHasBackButton() throws {
        sut.currentPage = .getStarted
        
        XCTAssertFalse(sut.hasBackButton)
        
        sut.currentPage = .acceptedInvitation
        
        XCTAssertTrue(sut.hasBackButton)
    }

    func testNextButtonEnabled() throws {
        sut.currentPage = .getStarted
        XCTAssertTrue(sut.nextButtonEnabled)
        
        sut.currentPage = .acceptedInvitation
        XCTAssertTrue(sut.nextButtonEnabled)
        
        sut.currentPage = .pendingInvitation
        XCTAssertTrue(sut.nextButtonEnabled)
        
        sut.currentPage = .nameArchive
        XCTAssertFalse(sut.nextButtonEnabled)
        sut.archiveName = "Test"
        XCTAssertTrue(sut.nextButtonEnabled)
        
        sut.currentPage = .createArchive
        XCTAssertFalse(sut.nextButtonEnabled)
        sut.archiveType = .family
        XCTAssertTrue(sut.nextButtonEnabled)
    }
    
    func testNextButtonHidden() throws {
        sut.currentPage = .getStarted
        XCTAssertFalse(sut.nextButtonHidden)
        
        sut.currentPage = .acceptedInvitation
        XCTAssertTrue(sut.nextButtonHidden)
        
        sut.currentPage = .pendingInvitation
        XCTAssertFalse(sut.nextButtonHidden)
        
        sut.currentPage = .nameArchive
        XCTAssertFalse(sut.nextButtonHidden)
        
        sut.currentPage = .createArchive
        XCTAssertFalse(sut.nextButtonHidden)
    }

    func testRightButtonTitle() throws {
        sut.currentPage = .getStarted
        XCTAssertTrue(sut.nextButtonTitle == "Get Started".localized())
        
        sut.currentPage = .acceptedInvitation
        XCTAssertTrue(sut.nextButtonTitle.isEmpty)
        
        sut.currentPage = .nameArchive
        XCTAssertTrue(sut.nextButtonTitle == "Create Archive".localized())
        
        sut.currentPage = .pendingInvitation
        XCTAssertTrue(sut.nextButtonTitle == "Accept All".localized())
        
        sut.currentPage = .createArchive
        XCTAssertTrue(sut.nextButtonTitle == "Next: Name Archive".localized())
    }
    
    func testLeftButtonTitle() throws {
        sut.currentPage = .getStarted
        XCTAssertTrue(sut.backButtonTitle.isEmpty)
        
        sut.currentPage = .acceptedInvitation
        XCTAssertTrue(sut.backButtonTitle == "Create New Archive".localized())
        
        sut.currentPage = .pendingInvitation
        XCTAssertTrue(sut.backButtonTitle == "Create New Archive".localized())
        
        sut.currentPage = .nameArchive
        XCTAssertTrue(sut.backButtonTitle == "Back".localized())
        
        sut.currentPage = .createArchive
        XCTAssertTrue(sut.backButtonTitle == "Back".localized())
    }
}
