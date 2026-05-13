//
//  OnboardingViewRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class OnboardingViewRenderingTests: XCTestCase {

    // MARK: - OnboardingContainerViewModel Tests

    func testOnboardingContainerViewModel_InitialState() {
        let vm = OnboardingContainerViewModel(username: "test@example.com", password: "pass123")

        XCTAssertEqual(vm.username, "test@example.com")
        XCTAssertEqual(vm.password, "pass123")
        XCTAssertEqual(vm.archiveName, "")
        XCTAssertEqual(vm.archiveType, .person)
        XCTAssertTrue(vm.selectedPath.isEmpty)
        XCTAssertTrue(vm.selectedWhatsImportant.isEmpty)
        XCTAssertTrue(vm.allArchives.isEmpty)
        XCTAssertFalse(vm.creatingNewArchive)
    }

    func testOnboardingContainerViewModel_NilCredentials() {
        let vm = OnboardingContainerViewModel(username: nil, password: nil)

        XCTAssertEqual(vm.username, "")
        XCTAssertEqual(vm.password, "")
    }

    func testOnboardingContainerViewModel_AllPropertiesCanBeSet() {
        let vm = OnboardingContainerViewModel(username: nil, password: nil)

        vm.contentType = .chartYourPath
        vm.archiveName = "My Archive"
        vm.archiveType = .family
        vm.selectedWhatsImportant = [.access, .preserving]
        vm.creatingNewArchive = true
        vm.isLoading = true
        vm.showAlert = true

        XCTAssertEqual(vm.contentType, .chartYourPath)
        XCTAssertEqual(vm.archiveName, "My Archive")
        XCTAssertEqual(vm.archiveType, .family)
        XCTAssertTrue(vm.selectedPath.isEmpty)
        XCTAssertEqual(vm.selectedWhatsImportant.count, 2)
        XCTAssertTrue(vm.selectedWhatsImportant.contains(.access))
        XCTAssertTrue(vm.creatingNewArchive)
        XCTAssertTrue(vm.isLoading)
        XCTAssertTrue(vm.showAlert)
    }

    // MARK: - OnboardingCongratulationsViewModel Tests

    func testOnboardingCongratulationsViewModel_InitialState() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingCongratulationsViewModel(containerViewModel: container)

        XCTAssertTrue(vm.containerViewModel === container)
    }

    func testOnboardingCongratulationsViewModel_AccessesContainerArchives() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingCongratulationsViewModel(containerViewModel: container)

        XCTAssertTrue(vm.containerViewModel.allArchives.isEmpty)
    }

    // MARK: - OnboardingWhatsImportantViewModel Tests

    func testOnboardingWhatsImportantViewModel_InitialState() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingWhatsImportantViewModel(containerViewModel: container)

        XCTAssertTrue(vm.containerViewModel === container)
        XCTAssertTrue(vm.containerViewModel.selectedWhatsImportant.isEmpty)
    }

    func testOnboardingWhatsImportantViewModel_ToggleAddsItem() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingWhatsImportantViewModel(containerViewModel: container)

        vm.toggleWhatsImportant(whatsImportant: .access)
        XCTAssertEqual(container.selectedWhatsImportant.count, 1)
        XCTAssertTrue(container.selectedWhatsImportant.contains(.access))
    }

    func testOnboardingWhatsImportantViewModel_ToggleRemovesExistingItem() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingWhatsImportantViewModel(containerViewModel: container)

        vm.toggleWhatsImportant(whatsImportant: .access)
        XCTAssertEqual(container.selectedWhatsImportant.count, 1)

        vm.toggleWhatsImportant(whatsImportant: .access)
        XCTAssertTrue(container.selectedWhatsImportant.isEmpty)
    }

    func testOnboardingWhatsImportantViewModel_ToggleMultipleItems() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingWhatsImportantViewModel(containerViewModel: container)

        vm.toggleWhatsImportant(whatsImportant: .access)
        vm.toggleWhatsImportant(whatsImportant: .preserving)
        vm.toggleWhatsImportant(whatsImportant: .professional)

        XCTAssertEqual(container.selectedWhatsImportant.count, 3)
        XCTAssertTrue(container.selectedWhatsImportant.contains(.access))
        XCTAssertTrue(container.selectedWhatsImportant.contains(.preserving))
        XCTAssertTrue(container.selectedWhatsImportant.contains(.professional))
    }

    func testOnboardingWhatsImportantViewModel_ToggleAndUntoggleMultiple() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingWhatsImportantViewModel(containerViewModel: container)

        vm.toggleWhatsImportant(whatsImportant: .access)
        vm.toggleWhatsImportant(whatsImportant: .supporting)
        vm.toggleWhatsImportant(whatsImportant: .collaborate)
        XCTAssertEqual(container.selectedWhatsImportant.count, 3)

        vm.toggleWhatsImportant(whatsImportant: .supporting)
        XCTAssertEqual(container.selectedWhatsImportant.count, 2)
        XCTAssertFalse(container.selectedWhatsImportant.contains(.supporting))
    }

    func testOnboardingWhatsImportantViewModel_ToggleSameItemTwiceRestoresEmpty() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingWhatsImportantViewModel(containerViewModel: container)

        vm.toggleWhatsImportant(whatsImportant: .preserving)
        vm.toggleWhatsImportant(whatsImportant: .preserving)
        XCTAssertTrue(container.selectedWhatsImportant.isEmpty)
    }

    // MARK: - OnboardingWhatsImportant Enum Tests

    func testOnboardingWhatsImportant_AllCasesExist() {
        let allCases = OnboardingWhatsImportant.allCases
        XCTAssertTrue(allCases.count >= 5)
    }

    func testOnboardingWhatsImportant_HasDescriptions() {
        XCTAssertFalse(OnboardingWhatsImportant.access.description.isEmpty)
        XCTAssertFalse(OnboardingWhatsImportant.supporting.description.isEmpty)
        XCTAssertFalse(OnboardingWhatsImportant.preserving.description.isEmpty)
        XCTAssertFalse(OnboardingWhatsImportant.professional.description.isEmpty)
        XCTAssertFalse(OnboardingWhatsImportant.collaborate.description.isEmpty)
    }

    func testOnboardingWhatsImportant_IsIdentifiable() {
        let item = OnboardingWhatsImportant.access
        XCTAssertFalse(item.id.isEmpty)
    }

    // MARK: - OnboardingCongratulationsView Rendering Tests

    func testOnboardingCongratulationsView_RendersWithoutCrash() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingCongratulationsViewModel(containerViewModel: container)

        let view = OnboardingCongratulationsView(viewModel: vm, backButton: {}, nextButton: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testOnboardingCongratulationsView_RendersWhileLoading() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        container.isLoading = true
        let vm = OnboardingCongratulationsViewModel(containerViewModel: container)

        let view = OnboardingCongratulationsView(viewModel: vm, backButton: {}, nextButton: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testOnboardingCongratulationsView_CallbacksAreStored() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingCongratulationsViewModel(containerViewModel: container)

        var backCalled = false
        var nextCalled = false

        let view = OnboardingCongratulationsView(
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

    // MARK: - OnboardingWhatsImportantView Rendering Tests

    func testOnboardingWhatsImportantView_RendersWithoutCrash() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingWhatsImportantViewModel(containerViewModel: container)

        let view = OnboardingWhatsImportantView(viewModel: vm, backButton: {}, nextButton: {}, skipButton: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testOnboardingWhatsImportantView_RendersWithSelectedItems() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        container.selectedWhatsImportant = [.access, .preserving]
        let vm = OnboardingWhatsImportantViewModel(containerViewModel: container)

        let view = OnboardingWhatsImportantView(viewModel: vm, backButton: {}, nextButton: {}, skipButton: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testOnboardingWhatsImportantView_RendersWhileLoading() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        container.isLoading = true
        let vm = OnboardingWhatsImportantViewModel(containerViewModel: container)

        let view = OnboardingWhatsImportantView(viewModel: vm, backButton: {}, nextButton: {}, skipButton: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - OnboardingView Rendering Tests

    func testOnboardingView_RendersWithDefaultState() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)

        let view = OnboardingView(viewModel: container)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testOnboardingView_RendersWithWelcomeContentType() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        container.contentType = .welcome

        let view = OnboardingView(viewModel: container)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testOnboardingView_RendersWithCongratulationsContentType() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        container.contentType = .congratulations

        let view = OnboardingView(viewModel: container)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testOnboardingView_RendersWithWhatsImportantContentType() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        container.contentType = .whatsImportant

        let view = OnboardingView(viewModel: container)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testOnboardingView_RendersWithChartYourPathContentType() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        container.contentType = .chartYourPath

        let view = OnboardingView(viewModel: container)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testOnboardingView_RendersWithCreateArchiveContentType() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        container.contentType = .createArchive

        let view = OnboardingView(viewModel: container)
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
