//
//  ChecklistAndDialogViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class ChecklistAndDialogViewTests: XCTestCase {

    // MARK: - ChecklistBottomMenuViewModel Initial State

    func testChecklistVM_InitialState() {
        let vm = ChecklistBottomMenuViewModel(showsChecklistButton: true)

        XCTAssertTrue(vm.showsChecklistButton)
        XCTAssertTrue(vm.items.isEmpty)
        XCTAssertFalse(vm.listCompleted)
        XCTAssertFalse(vm.showError)
    }

    func testChecklistVM_InitialState_ButtonHidden() {
        let vm = ChecklistBottomMenuViewModel(showsChecklistButton: false)

        XCTAssertFalse(vm.showsChecklistButton)
    }

    // MARK: - ChecklistBottomMenuViewModel Completion Percentage

    func testChecklistVM_CompletionPercentage_EmptyItems() {
        let vm = ChecklistBottomMenuViewModel(showsChecklistButton: true)

        XCTAssertEqual(vm.completionPercentage, 0)
    }

    func testChecklistVM_CompletionPercentage_AllCompleted() {
        let vm = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        vm.items = [
            ChecklistItem(type: .archiveCreated, completed: true),
            ChecklistItem(type: .firstUpload, completed: true)
        ]

        XCTAssertEqual(vm.completionPercentage, 100)
    }

    func testChecklistVM_CompletionPercentage_HalfCompleted() {
        let vm = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        vm.items = [
            ChecklistItem(type: .archiveCreated, completed: true),
            ChecklistItem(type: .firstUpload, completed: false)
        ]

        XCTAssertEqual(vm.completionPercentage, 50)
    }

    func testChecklistVM_CompletionPercentage_NoneCompleted() {
        let vm = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        vm.items = [
            ChecklistItem(type: .archiveCreated, completed: false),
            ChecklistItem(type: .firstUpload, completed: false)
        ]

        XCTAssertEqual(vm.completionPercentage, 0)
    }

    // MARK: - ChecklistBottomMenuViewModel State Changes

    func testChecklistVM_ChangeChecklistContent() {
        let vm = ChecklistBottomMenuViewModel(showsChecklistButton: true)

        vm.changeChecklistContent(.content)
        XCTAssertEqual(vm.viewState, .content)

        vm.changeChecklistContent(.error)
        XCTAssertEqual(vm.viewState, .error)

        vm.changeChecklistContent(.congrats)
        XCTAssertEqual(vm.viewState, .congrats)

        vm.changeChecklistContent(.dontShowAgain)
        XCTAssertEqual(vm.viewState, .dontShowAgain)
    }

    func testChecklistVM_BooleanFlagsCanBeSet() {
        let vm = ChecklistBottomMenuViewModel(showsChecklistButton: true)

        vm.listCompleted = true
        vm.showError = true

        XCTAssertTrue(vm.listCompleted)
        XCTAssertTrue(vm.showError)
    }

    // MARK: - ChecklistViewState Enum

    func testChecklistViewState_AllCases() {
        let loading: ChecklistViewState = .loading
        let content: ChecklistViewState = .content
        let dontShow: ChecklistViewState = .dontShowAgain
        let congrats: ChecklistViewState = .congrats
        let error: ChecklistViewState = .error

        XCTAssertNotNil(loading)
        XCTAssertNotNil(content)
        XCTAssertNotNil(dontShow)
        XCTAssertNotNil(congrats)
        XCTAssertNotNil(error)
    }

    // MARK: - ChecklistBottomMenuView Rendering Tests

    func testChecklistBottomMenuView_RendersWithoutCrash() {
        let view = ChecklistBottomMenuView(
            viewModel: StateObject(wrappedValue: ChecklistBottomMenuViewModel(showsChecklistButton: true)),
            dismissAction: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testChecklistBottomMenuView_RendersWithButtonHidden() {
        let view = ChecklistBottomMenuView(
            viewModel: StateObject(wrappedValue: ChecklistBottomMenuViewModel(showsChecklistButton: false)),
            dismissAction: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - CustomDialogView Tests

    func testCustomDialogView_RendersWithoutCrash() {
        var isActive = true
        let view = CustomDialogView(
            isActive: Binding(get: { isActive }, set: { isActive = $0 }),
            title: "Confirm",
            message: "Are you sure?",
            buttonTitle: "OK",
            action: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testCustomDialogView_RendersWithNilMessage() {
        var isActive = true
        let view = CustomDialogView(
            isActive: Binding(get: { isActive }, set: { isActive = $0 }),
            title: "Alert",
            message: nil,
            buttonTitle: "Continue",
            action: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testCustomDialogView_RendersWithCornerRadius() {
        var isActive = true
        let view = CustomDialogView(
            isActive: Binding(get: { isActive }, set: { isActive = $0 }),
            title: "Alert",
            message: "Test",
            buttonTitle: "OK",
            addCornerRadius: true,
            action: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - TwoStepTabletModalAlertView Tests

    func testTwoStepTabletModalAlertView_RendersWithoutCrash() {
        var showError = true
        var deleteMethod: TwoFactorMethod? = nil
        let view = TwoStepTabletModalAlertView(
            showErrorMessage: Binding(get: { showError }, set: { showError = $0 }),
            deleteMethodConfirmed: Binding(get: { deleteMethod }, set: { deleteMethod = $0 })
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testTwoStepTabletModalAlertView_RendersWithMethod() {
        var showError = true
        var deleteMethod: TwoFactorMethod? = nil
        let method = TwoFactorMethod(methodId: "1", method: "sms", value: "+1234567890")
        let view = TwoStepTabletModalAlertView(
            showErrorMessage: Binding(get: { showError }, set: { showError = $0 }),
            deleteMethodConfirmed: Binding(get: { deleteMethod }, set: { deleteMethod = $0 }),
            twoFactorMethod: method,
            deleteMessage: true
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - Helpers

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }
}
