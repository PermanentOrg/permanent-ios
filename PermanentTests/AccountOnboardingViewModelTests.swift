//
//  AccountOnboardingViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.05.2026.
//

import XCTest
@testable import Permanent

final class AccountOnboardingViewModelTests: XCTestCase {

    // MARK: - Page rightButtonTitle

    func testPage_GetStarted_RightTitle() {
        XCTAssertFalse(AccountOnboardingViewModel.Page.getStarted.rightButtonTitle.isEmpty)
    }

    func testPage_CreateArchive_RightTitle() {
        XCTAssertFalse(AccountOnboardingViewModel.Page.createArchive.rightButtonTitle.isEmpty)
    }

    func testPage_NameArchive_RightTitle() {
        XCTAssertFalse(AccountOnboardingViewModel.Page.nameArchive.rightButtonTitle.isEmpty)
    }

    func testPage_PendingInvitation_RightTitle() {
        XCTAssertFalse(AccountOnboardingViewModel.Page.pendingInvitation.rightButtonTitle.isEmpty)
    }

    func testPage_AcceptedInvitation_RightTitle_Empty() {
        XCTAssertTrue(AccountOnboardingViewModel.Page.acceptedInvitation.rightButtonTitle.isEmpty)
    }

    // MARK: - Page leftButtonTitle

    func testPage_GetStarted_LeftTitle_Empty() {
        XCTAssertTrue(AccountOnboardingViewModel.Page.getStarted.leftButtonTitle.isEmpty)
    }

    func testPage_NameArchive_LeftTitle_NotEmpty() {
        XCTAssertFalse(AccountOnboardingViewModel.Page.nameArchive.leftButtonTitle.isEmpty)
    }

    func testPage_CreateArchive_LeftTitle_NotEmpty() {
        XCTAssertFalse(AccountOnboardingViewModel.Page.createArchive.leftButtonTitle.isEmpty)
    }

    func testPage_PendingInvitation_LeftTitle_NotEmpty() {
        XCTAssertFalse(AccountOnboardingViewModel.Page.pendingInvitation.leftButtonTitle.isEmpty)
    }

    func testPage_AcceptedInvitation_LeftTitle_NotEmpty() {
        XCTAssertFalse(AccountOnboardingViewModel.Page.acceptedInvitation.leftButtonTitle.isEmpty)
    }

    // MARK: - Page nextButtonHidden

    func testPage_GetStarted_NextNotHidden() {
        XCTAssertFalse(AccountOnboardingViewModel.Page.getStarted.nextButtonHidden)
    }

    func testPage_CreateArchive_NextNotHidden() {
        XCTAssertFalse(AccountOnboardingViewModel.Page.createArchive.nextButtonHidden)
    }

    func testPage_NameArchive_NextNotHidden() {
        XCTAssertFalse(AccountOnboardingViewModel.Page.nameArchive.nextButtonHidden)
    }

    func testPage_PendingInvitation_NextNotHidden() {
        XCTAssertFalse(AccountOnboardingViewModel.Page.pendingInvitation.nextButtonHidden)
    }

    func testPage_AcceptedInvitation_NextHidden() {
        XCTAssertTrue(AccountOnboardingViewModel.Page.acceptedInvitation.nextButtonHidden)
    }

    // MARK: - Init

    func testInit_CurrentPage_IsGetStarted() {
        let vm = AccountOnboardingViewModel()
        XCTAssertTrue(vm.currentPage == .getStarted)
    }

    func testInit_ArchiveTypeNil() {
        let vm = AccountOnboardingViewModel()
        XCTAssertNil(vm.archiveType)
    }

    func testInit_ArchiveNameNil() {
        let vm = AccountOnboardingViewModel()
        XCTAssertNil(vm.archiveName)
    }

    func testInit_AccountNil() {
        let vm = AccountOnboardingViewModel()
        XCTAssertNil(vm.account)
    }

    func testInit_AccountArchivesEmpty() {
        let vm = AccountOnboardingViewModel()
        XCTAssertTrue(vm.accountArchives?.isEmpty ?? true)
    }

    func testInit_AcceptedArchivesEmpty() {
        let vm = AccountOnboardingViewModel()
        XCTAssertTrue(vm.acceptedArchives?.isEmpty ?? true)
    }

    // MARK: - hasBackButton

    func testHasBackButton_GetStarted_False() {
        let vm = AccountOnboardingViewModel()
        vm.currentPage = .getStarted
        XCTAssertFalse(vm.hasBackButton)
    }

    func testHasBackButton_CreateArchive_True() {
        let vm = AccountOnboardingViewModel()
        vm.currentPage = .createArchive
        XCTAssertTrue(vm.hasBackButton)
    }

    func testHasBackButton_NameArchive_True() {
        let vm = AccountOnboardingViewModel()
        vm.currentPage = .nameArchive
        XCTAssertTrue(vm.hasBackButton)
    }

    func testHasBackButton_PendingInvitation_True() {
        let vm = AccountOnboardingViewModel()
        vm.currentPage = .pendingInvitation
        XCTAssertTrue(vm.hasBackButton)
    }

    // MARK: - nextButtonTitle

    func testNextButtonTitle_GetStarted() {
        let vm = AccountOnboardingViewModel()
        vm.currentPage = .getStarted
        XCTAssertFalse(vm.nextButtonTitle.isEmpty)
    }

    func testNextButtonTitle_AcceptedInvitation_Empty() {
        let vm = AccountOnboardingViewModel()
        vm.currentPage = .acceptedInvitation
        XCTAssertTrue(vm.nextButtonTitle.isEmpty)
    }

    // MARK: - backButtonTitle

    func testBackButtonTitle_GetStarted_Empty() {
        let vm = AccountOnboardingViewModel()
        vm.currentPage = .getStarted
        XCTAssertTrue(vm.backButtonTitle.isEmpty)
    }

    func testBackButtonTitle_NameArchive_NotEmpty() {
        let vm = AccountOnboardingViewModel()
        vm.currentPage = .nameArchive
        XCTAssertFalse(vm.backButtonTitle.isEmpty)
    }

    // MARK: - nextButtonEnabled

    func testNextButtonEnabled_GetStarted_True() {
        let vm = AccountOnboardingViewModel()
        vm.currentPage = .getStarted
        XCTAssertTrue(vm.nextButtonEnabled)
    }

    func testNextButtonEnabled_CreateArchive_NoType_False() {
        let vm = AccountOnboardingViewModel()
        vm.currentPage = .createArchive
        vm.archiveType = nil
        XCTAssertFalse(vm.nextButtonEnabled)
    }

    func testNextButtonEnabled_CreateArchive_WithType_True() {
        let vm = AccountOnboardingViewModel()
        vm.currentPage = .createArchive
        vm.archiveType = .person
        XCTAssertTrue(vm.nextButtonEnabled)
    }

    func testNextButtonEnabled_NameArchive_NoName_False() {
        let vm = AccountOnboardingViewModel()
        vm.currentPage = .nameArchive
        vm.archiveName = nil
        XCTAssertFalse(vm.nextButtonEnabled)
    }

    func testNextButtonEnabled_NameArchive_WithName_True() {
        let vm = AccountOnboardingViewModel()
        vm.currentPage = .nameArchive
        vm.archiveName = "My Archive"
        XCTAssertTrue(vm.nextButtonEnabled)
    }

    func testNextButtonEnabled_PendingInvitation_True() {
        let vm = AccountOnboardingViewModel()
        vm.currentPage = .pendingInvitation
        XCTAssertTrue(vm.nextButtonEnabled)
    }

    // MARK: - nextButtonHidden

    func testNextButtonHidden_GetStarted_False() {
        let vm = AccountOnboardingViewModel()
        vm.currentPage = .getStarted
        XCTAssertFalse(vm.nextButtonHidden)
    }

    func testNextButtonHidden_AcceptedInvitation_True() {
        let vm = AccountOnboardingViewModel()
        vm.currentPage = .acceptedInvitation
        XCTAssertTrue(vm.nextButtonHidden)
    }

    // MARK: - Notification names

    func testArchiveTypeChanged_NotificationName() {
        XCTAssertEqual(AccountOnboardingViewModel.archiveTypeChanged.rawValue, "AccountOnboardingViewModel.archiveTypeChanged")
    }

    func testArchiveNameChanged_NotificationName() {
        XCTAssertEqual(AccountOnboardingViewModel.archiveNameChanged.rawValue, "AccountOnboardingViewModel.archiveNameChanged")
    }

    // MARK: - archiveType didSet posts notification

    func testArchiveType_PostsNotification() {
        let vm = AccountOnboardingViewModel()
        let expectation = expectation(forNotification: AccountOnboardingViewModel.archiveTypeChanged, object: vm)
        vm.archiveType = .person
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - archiveName didSet posts notification

    func testArchiveName_PostsNotification() {
        let vm = AccountOnboardingViewModel()
        let expectation = expectation(forNotification: AccountOnboardingViewModel.archiveNameChanged, object: vm)
        vm.archiveName = "Test"
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - finishOnboard edge cases

    func testFinishOnboard_NilArchiveName_ReturnsError() {
        let vm = AccountOnboardingViewModel()
        vm.archiveName = nil
        vm.archiveType = .person
        let expectation = expectation(description: "completion")

        vm.finishOnboard { response in
            if case .error = response {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testFinishOnboard_NilArchiveType_ReturnsError() {
        let vm = AccountOnboardingViewModel()
        vm.archiveName = "Test"
        vm.archiveType = nil
        let expectation = expectation(description: "completion")

        vm.finishOnboard { response in
            if case .error = response {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testFinishOnboard_BothNil_ReturnsError() {
        let vm = AccountOnboardingViewModel()
        vm.archiveName = nil
        vm.archiveType = nil
        let expectation = expectation(description: "completion")

        vm.finishOnboard { response in
            if case .error = response {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - acceptAllPendingArchives edge case

    func testAcceptAllPendingArchives_NilArchives_ReturnsError() {
        let vm = AccountOnboardingViewModel()
        vm.accountArchives = nil
        let expectation = expectation(description: "completion")

        vm.acceptAllPendingArchives { success, error in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testAcceptAllPendingArchives_EmptyArchives_Succeeds() {
        let vm = AccountOnboardingViewModel()
        vm.accountArchives = []
        let expectation = expectation(description: "completion")

        vm.acceptAllPendingArchives { success, error in
            XCTAssertTrue(success)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - updateAccount edge case

    func testUpdateAccount_NilAccount_ReturnsError() {
        let vm = AccountOnboardingViewModel()
        vm.account = nil
        let expectation = expectation(description: "completion")

        vm.updateAccount(withDefaultArchiveId: 1) { account, error in
            XCTAssertNil(account)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - changeArchive edge case

    func testChangeArchive_NilArchiveId_ReturnsError() {
        let vm = AccountOnboardingViewModel()
        let archive = ArchiveVOData(
            childFolderVOS: nil, folderSizeVOS: nil, recordVOS: nil,
            accessRole: nil, fullName: nil,
            spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil,
            relationType: nil, homeCity: nil, homeState: nil, homeCountry: nil,
            itemVOS: nil, birthDay: nil, company: nil, archiveVODescription: nil,
            archiveID: nil, publicDT: nil, archiveNbr: nil,
            view: nil, viewProperty: nil, archiveVOPublic: nil,
            vaultKey: nil, thumbArchiveNbr: nil, type: nil, thumbStatus: nil,
            imageRatio: nil, thumbnail256: nil, thumbURL200: nil, thumbURL500: nil,
            thumbURL1000: nil, thumbURL2000: nil, thumbDT: nil,
            createdDT: nil, updatedDT: nil, status: nil
        )
        let expectation = expectation(description: "completion")

        vm.changeArchive(archive) { success, error in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
