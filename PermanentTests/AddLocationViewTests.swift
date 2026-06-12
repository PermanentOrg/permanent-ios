//
//  AddLocationViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class AddLocationViewTests: XCTestCase {

    // MARK: - AddLocationViewModel Initial State

    func testViewModel_InitialState() {
        let vm = AddLocationViewModel(selectedFiles: [FileModel.mockFile()], commonLocation: nil)

        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.selectedPlace)
        XCTAssertNil(vm.selectedCoordinates)
        XCTAssertTrue(vm.searchedLocations.isEmpty)
        XCTAssertEqual(vm.debouncedText, "")
        XCTAssertEqual(vm.searchText, "")
        XCTAssertNil(vm.locnVO)
        XCTAssertFalse(vm.showConfirmation)
        XCTAssertFalse(vm.changesConfirmed)
        XCTAssertNil(vm.commonLocation)
    }

    func testViewModel_InitialState_EmptyFiles() {
        let vm = AddLocationViewModel(selectedFiles: [], commonLocation: nil)

        XCTAssertNotNil(vm)
    }

    // MARK: - AddLocationViewModel Properties

    func testViewModel_AllPropertiesCanBeSet() {
        let vm = AddLocationViewModel(selectedFiles: [FileModel.mockFile()], commonLocation: nil)

        vm.isLoading = true
        vm.searchText = "New York"
        vm.showConfirmation = true
        vm.changesConfirmed = true

        XCTAssertTrue(vm.isLoading)
        XCTAssertEqual(vm.searchText, "New York")
        XCTAssertTrue(vm.showConfirmation)
        XCTAssertTrue(vm.changesConfirmed)
    }

    // MARK: - AddLocationViewModel getAddressString

    func testViewModel_GetAddressString_WithLocnVO() {
        let vm = AddLocationViewModel(selectedFiles: [FileModel.mockFile()], commonLocation: nil)

        XCTAssertNotNil(vm.getAddressString())
    }

    // MARK: - AddLocationViewModel getDistance

    func testViewModel_GetDistance_NilInput() {
        let vm = AddLocationViewModel(selectedFiles: [FileModel.mockFile()], commonLocation: nil)

        let distance = vm.getDistance(from: nil)
        XCTAssertNil(distance)
    }

    func testViewModel_GetDistance_ValidInput() {
        let vm = AddLocationViewModel(selectedFiles: [FileModel.mockFile()], commonLocation: nil)

        let distance = vm.getDistance(from: NSNumber(value: 5.5))
        XCTAssertNotNil(distance)
    }

    // MARK: - AddLocationView Rendering Tests

    func testAddLocationView_RendersWithoutCrash() {
        let vm = AddLocationViewModel(selectedFiles: [FileModel.mockFile()], commonLocation: nil)
        let view = AddLocationView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testAddLocationView_RendersWithEmptyFiles() {
        let vm = AddLocationViewModel(selectedFiles: [], commonLocation: nil)
        let view = AddLocationView(viewModel: vm)
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
