//
//  ChecklistOptionsViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class ChecklistOptionsViewModelTests: XCTestCase {

    // MARK: - ChecklistOptionsViewModel Initial State

    func testViewModel_InitialState_EmptyItems() {
        let vm = ChecklistOptionsViewModel(items: [], completionPercentage: 0, showsChecklistButton: true)

        XCTAssertTrue(vm.items.isEmpty)
        XCTAssertEqual(vm.completionPercentage, 0)
        XCTAssertTrue(vm.showsChecklistButton)
    }

    func testViewModel_InitialState_WithItems() {
        let items = makeChecklistItems()
        let vm = ChecklistOptionsViewModel(items: items, completionPercentage: 50, showsChecklistButton: false)

        XCTAssertEqual(vm.items.count, items.count)
        XCTAssertEqual(vm.completionPercentage, 50)
        XCTAssertFalse(vm.showsChecklistButton)
    }

    // MARK: - ChecklistOptionsViewModel Properties

    func testViewModel_CompletionPercentageCanBeUpdated() {
        let vm = ChecklistOptionsViewModel(items: [], completionPercentage: 0, showsChecklistButton: true)

        vm.completionPercentage = 75
        XCTAssertEqual(vm.completionPercentage, 75)
    }

    func testViewModel_ShowsChecklistButtonCanBeToggled() {
        let vm = ChecklistOptionsViewModel(items: [], completionPercentage: 0, showsChecklistButton: true)

        vm.showsChecklistButton = false
        XCTAssertFalse(vm.showsChecklistButton)
    }

    func testViewModel_ItemsCanBeUpdated() {
        let vm = ChecklistOptionsViewModel(items: [], completionPercentage: 0, showsChecklistButton: true)

        vm.items = makeChecklistItems()
        XCTAssertFalse(vm.items.isEmpty)
    }

    // MARK: - ChecklistOptionsViewModel handleItemTap

    func testViewModel_HandleItemTap_CompletedItem_DoesNotCrash() throws {
        let items = makeChecklistItems()
        let vm = ChecklistOptionsViewModel(items: items, completionPercentage: 50, showsChecklistButton: true)

        let completedItem = try XCTUnwrap(items.first { $0.completed })
        vm.handleItemTap(completedItem)
        XCTAssertEqual(vm.items.count, items.count)
    }

    func testViewModel_HandleItemTap_IncompleteItem_DoesNotCrash() throws {
        let items = makeChecklistItems()
        let vm = ChecklistOptionsViewModel(items: items, completionPercentage: 50, showsChecklistButton: true)

        let incompleteItem = try XCTUnwrap(items.first { !$0.completed })
        vm.handleItemTap(incompleteItem)
        XCTAssertEqual(vm.items.count, items.count)
    }

    // MARK: - ChecklistItem Model

    func testChecklistItem_Creation() {
        let item = ChecklistItem(type: .archiveCreated)

        XCTAssertEqual(item.id, "archiveCreated")
        XCTAssertEqual(item.title, "Create your first archive")
        XCTAssertFalse(item.completed)
        XCTAssertEqual(item.type, .archiveCreated)
    }

    func testChecklistItem_CompletedState() {
        let item = ChecklistItem(type: .firstUpload, completed: true)

        XCTAssertTrue(item.completed)
        XCTAssertEqual(item.type, .firstUpload)
    }

    func testChecklistItemType_AllKnownCasesExist() {
        let knownCases: [ChecklistItemType] = [
            .archiveCreated, .storageRedeemed, .legacyContact,
            .archiveSteward, .archiveProfile, .firstUpload, .publishContent
        ]
        for type in knownCases {
            XCTAssertFalse(type.title.isEmpty, "\(type.rawValue) should have a title")
        }
        XCTAssertEqual(knownCases.count, 7)
    }

    // MARK: - ChecklistOptionsView Rendering

    func testChecklistOptionsView_RendersWithEmptyItems() {
        let view = ChecklistOptionsView(items: [], completionPercentage: 0, showsChecklistButton: true, onDisableChecklist: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testChecklistOptionsView_RendersWithItems() {
        let items = makeChecklistItems()
        let view = ChecklistOptionsView(items: items, completionPercentage: 50, showsChecklistButton: true, onDisableChecklist: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testChecklistOptionsView_RendersWithFullCompletion() {
        let items = [
            ChecklistItem(type: .archiveCreated, completed: true),
            ChecklistItem(type: .firstUpload, completed: true)
        ]
        let view = ChecklistOptionsView(items: items, completionPercentage: 100, showsChecklistButton: false, onDisableChecklist: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - Helpers

    private func makeChecklistItems() -> [ChecklistItem] {
        [
            ChecklistItem(type: .archiveCreated, completed: true),
            ChecklistItem(type: .firstUpload, completed: false),
            ChecklistItem(type: .archiveProfile, completed: false)
        ]
    }

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }
}
