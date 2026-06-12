//
//  OnboardingInvitedWelcomeViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class OnboardingInvitedWelcomeViewTests: XCTestCase {

    // MARK: - OnboardingInvitedWelcomeViewModel Initial State

    func testViewModel_InitialState() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)

        XCTAssertFalse(vm.isArchiveAccepted)
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.showAlert)
        XCTAssertTrue(vm.containerViewModel === container)
    }

    // MARK: - OnboardingInvitedWelcomeViewModel Properties

    func testViewModel_AllPropertiesCanBeSet() {
        let container = OnboardingContainerViewModel(username: "user@test.com", password: "pass")
        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)

        vm.isArchiveAccepted = true
        vm.isLoading = true
        vm.showAlert = true

        XCTAssertTrue(vm.isArchiveAccepted)
        XCTAssertTrue(vm.isLoading)
        XCTAssertTrue(vm.showAlert)
        XCTAssertTrue(vm.containerViewModel.allArchives.isEmpty)
    }

    // MARK: - OnboardingInvitedWelcomeView Rendering Tests

    func testView_RendersWithoutCrash() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)
        let view = OnboardingInvitedWelcomeView(
            viewModel: vm,
            nextButtonAction: {},
            newArchiveButtonAction: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testView_RendersWhileLoading() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        container.isLoading = true
        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)
        let view = OnboardingInvitedWelcomeView(
            viewModel: vm,
            nextButtonAction: {},
            newArchiveButtonAction: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testView_CallbacksAreStored() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)

        var nextCalled = false
        var newArchiveCalled = false

        let view = OnboardingInvitedWelcomeView(
            viewModel: vm,
            nextButtonAction: { nextCalled = true },
            newArchiveButtonAction: { newArchiveCalled = true }
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
        XCTAssertFalse(nextCalled)
        XCTAssertFalse(newArchiveCalled)
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
