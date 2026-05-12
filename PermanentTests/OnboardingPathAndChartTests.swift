//
//  OnboardingPathAndChartTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class OnboardingPathAndChartTests: XCTestCase {

    // MARK: - OnboardingPath Enum

    func testOnboardingPath_AllCasesCount() {
        XCTAssertEqual(OnboardingPath.allCases.count, 8)
    }

    func testOnboardingPath_IdMatchesRawValue() {
        for path in OnboardingPath.allCases {
            XCTAssertEqual(path.id, path.rawValue)
        }
    }

    func testOnboardingPath_SomethingElseHasEmptyRawValue() {
        XCTAssertEqual(OnboardingPath.somethingElse.rawValue, "")
    }

    // MARK: - OnboardingChartYourPathViewModel

    func testChartPath_TogglePath_AddsAndRemoves() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingChartYourPathViewModel(containerViewModel: container)

        vm.togglePath(path: .capture)
        XCTAssertTrue(container.selectedPath.contains(.capture))

        vm.togglePath(path: .capture)
        XCTAssertFalse(container.selectedPath.contains(.capture))
    }

    func testChartPath_TogglePath_MultiplePaths() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingChartYourPathViewModel(containerViewModel: container)

        vm.togglePath(path: .capture)
        vm.togglePath(path: .organize)
        vm.togglePath(path: .collaborate)

        XCTAssertEqual(container.selectedPath.count, 3)
        XCTAssertTrue(container.selectedPath.contains(.capture))
        XCTAssertTrue(container.selectedPath.contains(.organize))
        XCTAssertTrue(container.selectedPath.contains(.collaborate))
    }

    func testChartPath_TogglePath_RemoveMiddlePath() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingChartYourPathViewModel(containerViewModel: container)

        vm.togglePath(path: .capture)
        vm.togglePath(path: .organize)
        vm.togglePath(path: .collaborate)
        vm.togglePath(path: .organize)

        XCTAssertEqual(container.selectedPath.count, 2)
        XCTAssertFalse(container.selectedPath.contains(.organize))
    }
}
