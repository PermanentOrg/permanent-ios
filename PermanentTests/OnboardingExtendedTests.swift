//
//  OnboardingExtendedTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class OnboardingExtendedTests: XCTestCase {

    // MARK: - OnboardingContainerViewModel Extended Properties

    func testContainerVM_AllPropertiesCanBeSet() {
        let vm = OnboardingContainerViewModel(username: nil, password: nil)

        vm.archiveName = "My Archive"
        vm.archiveType = .family
        vm.isLoading = true
        vm.showAlert = true
        vm.isBack = true

        XCTAssertEqual(vm.archiveName, "My Archive")
        XCTAssertEqual(vm.archiveType, .family)
        XCTAssertTrue(vm.isLoading)
        XCTAssertTrue(vm.showAlert)
        XCTAssertTrue(vm.isBack)
    }

    func testContainerVM_CollectionsCanBeModified() {
        let vm = OnboardingContainerViewModel(username: nil, password: nil)

        XCTAssertTrue(vm.selectedPath.isEmpty)
        vm.selectedPath.append(.capture)
        XCTAssertEqual(vm.selectedPath.count, 1)
        XCTAssertTrue(vm.selectedPath.contains(.capture))

        XCTAssertTrue(vm.selectedWhatsImportant.isEmpty)
        vm.selectedWhatsImportant.append(.access)
        XCTAssertEqual(vm.selectedWhatsImportant.count, 1)
    }

    func testContainerVM_AllArchivesInitiallyEmpty() {
        let vm = OnboardingContainerViewModel(username: nil, password: nil)

        XCTAssertTrue(vm.allArchives.isEmpty)
    }

    func testContainerVM_WithCredentials() {
        let vm = OnboardingContainerViewModel(username: "user@test.com", password: "pass123")

        XCTAssertEqual(vm.username, "user@test.com")
        XCTAssertEqual(vm.password, "pass123")
    }

    // MARK: - OnboardingChartYourPathViewModel

    func testChartYourPathVM_InitialState() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingChartYourPathViewModel(containerViewModel: container)

        XCTAssertTrue(vm.containerViewModel === container)
    }

    func testChartYourPathVM_TogglePath_AddsPath() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingChartYourPathViewModel(containerViewModel: container)

        vm.togglePath(path: .capture)
        XCTAssertTrue(container.selectedPath.contains(.capture))
    }

    func testChartYourPathVM_TogglePath_RemovesPath() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingChartYourPathViewModel(containerViewModel: container)

        vm.togglePath(path: .capture)
        vm.togglePath(path: .capture)
        XCTAssertFalse(container.selectedPath.contains(.capture))
    }

    func testChartYourPathVM_TogglePath_MultiplePaths() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingChartYourPathViewModel(containerViewModel: container)

        vm.togglePath(path: .capture)
        vm.togglePath(path: .digitize)
        vm.togglePath(path: .collaborate)

        XCTAssertEqual(container.selectedPath.count, 3)
        XCTAssertTrue(container.selectedPath.contains(.capture))
        XCTAssertTrue(container.selectedPath.contains(.digitize))
        XCTAssertTrue(container.selectedPath.contains(.collaborate))
    }

    func testChartYourPathVM_TogglePath_DeselectMiddle() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingChartYourPathViewModel(containerViewModel: container)

        vm.togglePath(path: .capture)
        vm.togglePath(path: .digitize)
        vm.togglePath(path: .collaborate)
        vm.togglePath(path: .digitize)

        XCTAssertEqual(container.selectedPath.count, 2)
        XCTAssertTrue(container.selectedPath.contains(.capture))
        XCTAssertFalse(container.selectedPath.contains(.digitize))
        XCTAssertTrue(container.selectedPath.contains(.collaborate))
    }

    // MARK: - OnboardingWhatsImportantViewModel

    func testWhatsImportantVM_InitialState() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingWhatsImportantViewModel(containerViewModel: container)

        XCTAssertTrue(vm.containerViewModel === container)
    }

    func testWhatsImportantVM_ToggleWhatsImportant_Adds() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingWhatsImportantViewModel(containerViewModel: container)

        vm.toggleWhatsImportant(whatsImportant: .access)
        XCTAssertTrue(container.selectedWhatsImportant.contains(.access))
    }

    func testWhatsImportantVM_ToggleWhatsImportant_Removes() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingWhatsImportantViewModel(containerViewModel: container)

        vm.toggleWhatsImportant(whatsImportant: .access)
        vm.toggleWhatsImportant(whatsImportant: .access)
        XCTAssertFalse(container.selectedWhatsImportant.contains(.access))
    }

    func testWhatsImportantVM_ToggleWhatsImportant_Multiple() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingWhatsImportantViewModel(containerViewModel: container)

        vm.toggleWhatsImportant(whatsImportant: .access)
        vm.toggleWhatsImportant(whatsImportant: .preserving)
        vm.toggleWhatsImportant(whatsImportant: .supporting)

        XCTAssertEqual(container.selectedWhatsImportant.count, 3)
    }

    // MARK: - OnboardingCongratulationsViewModel

    func testCongratulationsVM_InitialState() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingCongratulationsViewModel(containerViewModel: container)

        XCTAssertTrue(vm.containerViewModel === container)
    }

    // MARK: - OnboardingCreateFirstArchiveViewModel

    func testCreateFirstArchiveVM_InitialState() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingCreateFirstArchiveViewModel(containerViewModel: container)

        XCTAssertTrue(vm.containerViewModel === container)
    }

    // MARK: - OnboardingPath Enum

    func testOnboardingPath_AllCasesExist() {
        let allCases = OnboardingPath.allCases
        XCTAssertEqual(allCases.count, 8)
        XCTAssertTrue(allCases.contains(.capture))
        XCTAssertTrue(allCases.contains(.digitize))
        XCTAssertTrue(allCases.contains(.collaborate))
        XCTAssertTrue(allCases.contains(.organize))
    }

    // MARK: - OnboardingWhatsImportant Enum

    func testOnboardingWhatsImportant_AllCasesExist() {
        let allCases = OnboardingWhatsImportant.allCases
        XCTAssertEqual(allCases.count, 6)
        XCTAssertTrue(allCases.contains(.access))
        XCTAssertTrue(allCases.contains(.supporting))
        XCTAssertTrue(allCases.contains(.preserving))
    }

    // MARK: - View Rendering

    func testOnboardingChartYourPathView_Renders() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingChartYourPathViewModel(containerViewModel: container)
        let view = OnboardingChartYourPathView(viewModel: vm, backButton: {}, nextButton: {}, skipButton: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testOnboardingWhatsImportantView_Renders() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingWhatsImportantViewModel(containerViewModel: container)
        let view = OnboardingWhatsImportantView(viewModel: vm, backButton: {}, nextButton: {}, skipButton: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testOnboardingCongratulationsView_Renders() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingCongratulationsViewModel(containerViewModel: container)
        let view = OnboardingCongratulationsView(viewModel: vm, backButton: {}, nextButton: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testOnboardingCreateFirstArchiveView_Renders() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingCreateFirstArchiveViewModel(containerViewModel: container)
        let view = OnboardingCreateFirstArchiveView(viewModel: vm, backButton: {}, nextButton: {})
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
