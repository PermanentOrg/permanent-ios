//
//  OnboardingContainerViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class OnboardingContainerViewModelTests: XCTestCase {

    // MARK: - Initial State

    func testInit_NilCredentials_DefaultState() {
        let vm = OnboardingContainerViewModel(username: nil, password: nil)

        XCTAssertFalse(vm.isBack)
        XCTAssertFalse(vm.isArchiveAccepted)
        XCTAssertEqual(vm.archiveType, .person)
        XCTAssertEqual(vm.archiveName, "")
        XCTAssertTrue(vm.selectedPath.isEmpty)
        XCTAssertTrue(vm.selectedWhatsImportant.isEmpty)
        XCTAssertTrue(vm.allArchives.isEmpty)
        XCTAssertTrue(vm.allArchivesVO.isEmpty)
        XCTAssertEqual(vm.fullName, "")
        XCTAssertEqual(vm.bottomButtonsPadding, 40)
        XCTAssertEqual(vm.contentType, .none)
        XCTAssertEqual(vm.username, "")
        XCTAssertEqual(vm.password, "")
    }

    func testInit_WithCredentials_StoresValues() {
        let vm = OnboardingContainerViewModel(username: "user@test.com", password: "password123")

        XCTAssertEqual(vm.username, "user@test.com")
        XCTAssertEqual(vm.password, "password123")
    }

    // MARK: - Archive Properties

    func testArchiveType_AcceptsAllCases() {
        let vm = OnboardingContainerViewModel(username: nil, password: nil)

        for type in ArchiveType.allCases {
            vm.archiveType = type
            XCTAssertEqual(vm.archiveType, type)
        }
    }

    // MARK: - Path Selection

    func testSelectedPath_AddAndRemove() {
        let vm = OnboardingContainerViewModel(username: nil, password: nil)

        vm.selectedPath = [.capture, .digitize, .organize]
        XCTAssertEqual(vm.selectedPath.count, 3)

        vm.selectedPath = []
        XCTAssertTrue(vm.selectedPath.isEmpty)
    }

    func testSelectedPath_AcceptsAllOptions() {
        let vm = OnboardingContainerViewModel(username: nil, password: nil)
        vm.selectedPath = OnboardingPath.allCases
        XCTAssertEqual(vm.selectedPath.count, OnboardingPath.allCases.count)
    }

    // MARK: - Archives

    func testAllArchives_CanBePopulated() throws {
        let vm = OnboardingContainerViewModel(username: nil, password: nil)

        let archive = OnboardingArchive(
            fullname: "Test",
            accessType: "access.role.viewer",
            status: .ok,
            archiveID: 1,
            thumbnailURL: "",
            isThumbnailGenerated: false
        )
        vm.allArchives = [archive]
        XCTAssertEqual(vm.allArchives.count, 1)
        let firstArchive = try XCTUnwrap(vm.allArchives.first)
        XCTAssertEqual(firstArchive.fullname, "Test")
    }
}
