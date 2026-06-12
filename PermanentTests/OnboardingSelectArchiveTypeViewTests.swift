//
//  OnboardingSelectArchiveTypeViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class OnboardingSelectArchiveTypeViewTests: XCTestCase {

    // MARK: - OnboardingSelectArchiveTypeViewModel

    func testViewModel_InitialState() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingSelectArchiveTypeViewModel(containerViewModel: container)

        XCTAssertTrue(vm.containerViewModel === container)
    }

    func testViewModel_ContainerArchiveTypeCanBeSet() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingSelectArchiveTypeViewModel(containerViewModel: container)

        container.archiveType = .person
        XCTAssertEqual(vm.containerViewModel.archiveType, .person)
    }

    // MARK: - ArchiveType Enum

    func testArchiveType_AllCasesExist() {
        let allCases = ArchiveType.allCases
        XCTAssertEqual(allCases.count, 9)
    }

    func testArchiveType_ExcludesNonProfitInFiltered() {
        let filtered = ArchiveType.allCases.filter { $0 != .nonProfit }
        XCTAssertFalse(filtered.contains(.nonProfit))
        XCTAssertTrue(filtered.contains(.person))
        XCTAssertTrue(filtered.contains(.family))
        XCTAssertTrue(filtered.contains(.organization))
    }

    func testArchiveType_CommonCasesAreFilterable() {
        let allCases = ArchiveType.allCases
        XCTAssertTrue(allCases.contains(.person))
        XCTAssertTrue(allCases.contains(.family))
        XCTAssertTrue(allCases.contains(.organization))
    }

    // MARK: - OnboardingSelectArchiveTypeView Rendering

    func testView_RendersWithoutCrash() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingSelectArchiveTypeViewModel(containerViewModel: container)
        let view = OnboardingSelectArchiveTypeView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testView_RendersWithCredentials() {
        let container = OnboardingContainerViewModel(username: "user@test.com", password: "pass123")
        let vm = OnboardingSelectArchiveTypeViewModel(containerViewModel: container)
        let view = OnboardingSelectArchiveTypeView(viewModel: vm)
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
