//
//  OnboardingArchiveNameViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class OnboardingArchiveNameViewTests: XCTestCase {

    // MARK: - OnboardingArchiveNameViewModel Tests

    func testViewModel_InitialState() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingArchiveNameViewModel(containerViewModel: container)

        XCTAssertTrue(vm.containerViewModel === container)
    }

    func testViewModel_ContainerPropertiesCanBeSetThroughVM() {
        let container = OnboardingContainerViewModel(username: "user@test.com", password: "pass")
        let vm = OnboardingArchiveNameViewModel(containerViewModel: container)

        vm.containerViewModel.archiveName = "Family Photos"
        vm.containerViewModel.archiveType = .family
        vm.containerViewModel.contentType = .createArchive

        XCTAssertEqual(container.archiveName, "Family Photos")
        XCTAssertEqual(container.archiveType, .family)
        XCTAssertEqual(container.contentType, .createArchive)
        XCTAssertEqual(vm.containerViewModel.username, "user@test.com")
        XCTAssertEqual(vm.containerViewModel.password, "pass")
    }

    // MARK: - OnboardingArchiveNameView Rendering Tests

    func testOnboardingArchiveNameView_RendersWithoutCrash() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingArchiveNameViewModel(containerViewModel: container)
        let view = OnboardingArchiveNameView(viewModel: vm, backButton: {}, nextButton: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testOnboardingArchiveNameView_RendersWithArchiveName() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        container.archiveName = "My Archive"
        let vm = OnboardingArchiveNameViewModel(containerViewModel: container)
        let view = OnboardingArchiveNameView(viewModel: vm, backButton: {}, nextButton: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testOnboardingArchiveNameView_RendersWhileLoading() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        container.isLoading = true
        let vm = OnboardingArchiveNameViewModel(containerViewModel: container)
        let view = OnboardingArchiveNameView(viewModel: vm, backButton: {}, nextButton: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testOnboardingArchiveNameView_CallbacksAreStored() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingArchiveNameViewModel(containerViewModel: container)

        var backCalled = false
        var nextCalled = false

        let view = OnboardingArchiveNameView(
            viewModel: vm,
            backButton: { backCalled = true },
            nextButton: { nextCalled = true }
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
        XCTAssertFalse(backCalled)
        XCTAssertFalse(nextCalled)
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
