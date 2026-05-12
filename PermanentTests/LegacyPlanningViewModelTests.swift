//
//  LegacyPlanningViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class LegacyPlanningViewModelTests: XCTestCase {

    // MARK: - Initial State

    func testViewModel_InitialState() {
        let vm = LegacyPlanningViewModel()

        XCTAssertNil(vm.selectedArchive)
        XCTAssertNil(vm.selectedSteward)
        XCTAssertNil(vm.account)
        XCTAssertNil(vm.stewardType)
        XCTAssertFalse(vm.hasAccountSteward)
    }

    func testViewModel_InitialState_CallbacksAreNil() {
        let vm = LegacyPlanningViewModel()

        XCTAssertNil(vm.isLoading)
        XCTAssertNil(vm.stewardWasUpdated)
        XCTAssertNil(vm.showError)
        XCTAssertNil(vm.stewardWasSaved)
        XCTAssertNil(vm.accountStewardStatusUpdated)
    }

    // MARK: - Property Setting

    func testViewModel_AllPropertiesCanBeSet() {
        let vm = LegacyPlanningViewModel()

        vm.selectedArchive = ArchiveVOData.mock()
        vm.selectedSteward = LegacyPlanningSteward(
            name: "Jane Doe",
            email: "jane@test.com",
            note: "Test note",
            status: .pending,
            type: .archive
        )
        vm.stewardType = .archive
        vm.hasAccountSteward = true

        XCTAssertNotNil(vm.selectedArchive)
        XCTAssertEqual(vm.selectedSteward?.name, "Jane Doe")
        XCTAssertEqual(vm.selectedSteward?.email, "jane@test.com")
        XCTAssertEqual(vm.stewardType, .archive)
        XCTAssertTrue(vm.hasAccountSteward)
    }

    // MARK: - Callbacks

    func testViewModel_IsLoadingCallbackCanBeSet() {
        let vm = LegacyPlanningViewModel()
        var loadingValue: Bool?

        vm.isLoading = { loading in
            loadingValue = loading
        }

        vm.isLoading?(true)
        XCTAssertEqual(loadingValue, true)

        vm.isLoading?(false)
        XCTAssertEqual(loadingValue, false)
    }

    func testViewModel_StewardWasUpdatedCallbackCanBeSet() {
        let vm = LegacyPlanningViewModel()
        var updatedValue: Bool?

        vm.stewardWasUpdated = { updated in
            updatedValue = updated
        }

        vm.stewardWasUpdated?(true)
        XCTAssertEqual(updatedValue, true)
    }

    func testViewModel_StewardWasSavedCallbackCanBeSet() {
        let vm = LegacyPlanningViewModel()
        var savedValue: Bool?

        vm.stewardWasSaved = { saved in
            savedValue = saved
        }

        vm.stewardWasSaved?(true)
        XCTAssertEqual(savedValue, true)
    }

    // MARK: - LegacyPlanningSteward Model

    func testLegacyPlanningSteward_Creation() {
        let steward = LegacyPlanningSteward(
            name: "John Doe",
            email: "john@example.com",
            note: "Important note",
            status: .pending,
            type: .archive
        )

        XCTAssertEqual(steward.name, "John Doe")
        XCTAssertEqual(steward.email, "john@example.com")
        XCTAssertEqual(steward.note, "Important note")
        XCTAssertEqual(steward.status, .pending)
        XCTAssertEqual(steward.type, .archive)
    }

    func testLegacyPlanningSteward_StatusValuesAreDistinct() {
        let statuses: [LegacyPlanningSteward.StewardStatus] = [.pending, .accepted, .declined]
        let unique = Set(statuses.map { "\($0)" })
        XCTAssertEqual(unique.count, statuses.count, "All StewardStatus cases should be distinct")
    }

    func testLegacyPlanningSteward_TypeValuesAreDistinct() {
        let types: [LegacyPlanningSteward.StewardType] = [.account, .archive]
        XCTAssertNotEqual(
            "\(LegacyPlanningSteward.StewardType.account)",
            "\(LegacyPlanningSteward.StewardType.archive)"
        )
        XCTAssertEqual(types.count, 2)
    }

    func testLegacyPlanningSteward_DefaultId() {
        let steward = LegacyPlanningSteward(
            name: "Test",
            email: "test@test.com",
            status: .pending,
            type: .account
        )

        XCTAssertEqual(steward.id, "")
    }

    func testLegacyPlanningSteward_NilNote() {
        let steward = LegacyPlanningSteward(
            name: "Test",
            email: "test@test.com",
            note: nil,
            status: .accepted,
            type: .account
        )

        XCTAssertNil(steward.note)
    }

    // MARK: - ViewModelInterface Protocol

    func testViewModel_ConformsToViewModelInterface() {
        let vm = LegacyPlanningViewModel()

        vm.viewDidLoad()
        vm.viewWillAppear()
        vm.viewWillDisappear()
        XCTAssertNil(vm.selectedArchive)
    }
}
