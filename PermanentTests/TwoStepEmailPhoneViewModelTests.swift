//
//  TwoStepEmailPhoneViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

final class TwoStepEmailPhoneViewModelTests: XCTestCase {

    private func makeContainer() -> TwoStepConfirmationContainerViewModel {
        var refreshSecurity = false
        var methodForDelete: TwoFactorMethod? = nil
        var bannerMessage: BannerBottomMessage = .none

        return TwoStepConfirmationContainerViewModel(
            refreshSecurityView: Binding(get: { refreshSecurity }, set: { refreshSecurity = $0 }),
            methodSelectedForDelete: Binding(get: { methodForDelete }, set: { methodForDelete = $0 }),
            twoStepVerificationBottomBannerMessage: Binding(get: { bannerMessage }, set: { bannerMessage = $0 })
        )
    }

    // MARK: - TwoStepChooseEmailViewModel Initial State

    func testEmailVM_InitialState() {
        let container = makeContainer()
        let vm = TwoStepChooseEmailViewModel(containerViewModel: container)

        XCTAssertEqual(vm.textFieldEmail, "")
        XCTAssertFalse(vm.isLoadingEmailValidation)
        XCTAssertFalse(vm.isLoadingCodeVerification)
        XCTAssertFalse(vm.emailAlreadyConfirmed)
        XCTAssertEqual(vm.remainingTime, 0)
        XCTAssertTrue(vm.canResend)
        XCTAssertEqual(vm.sendCodeButtonTitle, "Send Code")
        XCTAssertEqual(vm.pinCode, "")
    }

    func testEmailVM_AllPropertiesCanBeSet() {
        let container = makeContainer()
        let vm = TwoStepChooseEmailViewModel(containerViewModel: container)

        vm.textFieldEmail = "user@test.com"
        vm.pinCode = "123456"
        vm.isLoadingEmailValidation = true
        vm.isLoadingCodeVerification = true

        XCTAssertEqual(vm.textFieldEmail, "user@test.com")
        XCTAssertEqual(vm.pinCode, "123456")
        XCTAssertTrue(vm.isLoadingEmailValidation)
        XCTAssertTrue(vm.isLoadingCodeVerification)
    }

    // MARK: - TwoStepChoosePhoneViewModel Initial State

    func testPhoneVM_InitialState() {
        let container = makeContainer()
        let vm = TwoStepChoosePhoneViewModel(containerViewModel: container)

        XCTAssertEqual(vm.formattedPhone, "")
        XCTAssertEqual(vm.rawPhone, "")
        XCTAssertFalse(vm.isLoadingPhoneValidation)
        XCTAssertFalse(vm.isLoadingCodeVerification)
        XCTAssertFalse(vm.phoneAlreadyConfirmed)
        XCTAssertEqual(vm.remainingTime, 0)
        XCTAssertTrue(vm.canResend)
        XCTAssertEqual(vm.sendCodeButtonTitle, "Send Code")
        XCTAssertEqual(vm.pinCode, "")
    }

    func testPhoneVM_AllPropertiesCanBeSet() {
        let container = makeContainer()
        let vm = TwoStepChoosePhoneViewModel(containerViewModel: container)

        vm.formattedPhone = "+1 555-123-4567"
        vm.rawPhone = "5551234567"
        vm.pinCode = "654321"
        vm.isLoadingPhoneValidation = true
        vm.isLoadingCodeVerification = true

        XCTAssertEqual(vm.formattedPhone, "+1 555-123-4567")
        XCTAssertEqual(vm.rawPhone, "5551234567")
        XCTAssertEqual(vm.pinCode, "654321")
        XCTAssertTrue(vm.isLoadingPhoneValidation)
        XCTAssertTrue(vm.isLoadingCodeVerification)
    }

    // MARK: - ChecklistBottomMenuViewModel

    func testChecklistBottomMenu_CompletionPercentage_Empty() {
        let vm = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        vm.items = []
        XCTAssertEqual(vm.completionPercentage, 0)
    }

    func testChecklistBottomMenu_CompletionPercentage_AllCompleted() {
        let vm = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        vm.items = [
            ChecklistItem(type: .archiveCreated, completed: true),
            ChecklistItem(type: .firstUpload, completed: true)
        ]
        XCTAssertEqual(vm.completionPercentage, 100)
    }

    func testChecklistBottomMenu_CompletionPercentage_Half() {
        let vm = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        vm.items = [
            ChecklistItem(type: .archiveCreated, completed: true),
            ChecklistItem(type: .firstUpload, completed: false)
        ]
        XCTAssertEqual(vm.completionPercentage, 50)
    }

    func testChecklistBottomMenu_CompletionPercentage_NoneCompleted() {
        let vm = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        vm.items = [
            ChecklistItem(type: .archiveCreated, completed: false),
            ChecklistItem(type: .firstUpload, completed: false),
            ChecklistItem(type: .legacyContact, completed: false)
        ]
        XCTAssertEqual(vm.completionPercentage, 0)
    }

    func testChecklistBottomMenu_ShowsChecklistButton() {
        let vm = ChecklistBottomMenuViewModel(showsChecklistButton: false)
        XCTAssertFalse(vm.showsChecklistButton)
    }

    func testChecklistBottomMenu_ChangeViewState() {
        let vm = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        vm.changeChecklistContent(.error)
        XCTAssertEqual(vm.viewState, .error)

        vm.changeChecklistContent(.congrats)
        XCTAssertEqual(vm.viewState, .congrats)
    }

    // MARK: - ChecklistViewState

    func testChecklistViewState_AllValues() {
        let loading = ChecklistViewState.loading
        let content = ChecklistViewState.content
        let dontShow = ChecklistViewState.dontShowAgain
        let congrats = ChecklistViewState.congrats
        let error = ChecklistViewState.error

        XCTAssertNotNil(loading)
        XCTAssertNotNil(content)
        XCTAssertNotNil(dontShow)
        XCTAssertNotNil(congrats)
        XCTAssertNotNil(error)
    }

    // MARK: - OnboardingInvitedWelcomeViewModel

    func testOnboardingInvitedWelcome_InitialState() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)

        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.showAlert)
        XCTAssertFalse(vm.isArchiveAccepted)
        XCTAssertNotNil(vm.containerViewModel)
    }

    // MARK: - OnboardingArchiveNameViewModel

    func testOnboardingArchiveName_Init() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingArchiveNameViewModel(containerViewModel: container)

        XCTAssertNotNil(vm.containerViewModel)
    }
}
