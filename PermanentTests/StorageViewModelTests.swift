//
//  StorageViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class StorageViewModelTests: XCTestCase {

    // MARK: - StorageViewModel Initial State

    func testViewModel_InitialState() {
        let vm = StorageViewModel()

        XCTAssertNil(vm.accountData)
        XCTAssertFalse(vm.addStorageIsPresented)
        XCTAssertFalse(vm.giftStorageIsPresented)
        XCTAssertFalse(vm.redeemStorageIspresented)
        XCTAssertFalse(vm.showRedeemNotifView)
        XCTAssertNil(vm.redeemCodeFromUrl)
        XCTAssertEqual(vm.spaceRatio, 0.0)
        XCTAssertEqual(vm.spaceTotal, 0)
        XCTAssertEqual(vm.spaceLeft, 0)
        XCTAssertEqual(vm.spaceUsed, 0)
        XCTAssertEqual(vm.spaceTotalReadable, "")
        XCTAssertEqual(vm.spaceLeftReadable, "")
        XCTAssertEqual(vm.spaceUsedReadable, "")
        // showError may be true if no session is active (getAccountInfo fails in init)
        XCTAssertFalse(vm.showRedeemCodeView)
        XCTAssertFalse(vm.showRedeemNotif)
        XCTAssertEqual(vm.redeemAmmountConverted, "")
        XCTAssertEqual(vm.redeemAmmountInt, 0)
    }

    func testViewModel_InitialState_WithRedeemCode() {
        let vm = StorageViewModel(reddemCode: "PROMO2026")

        XCTAssertEqual(vm.redeemCodeFromUrl, "PROMO2026")
    }

    func testViewModel_InitialState_NilRedeemCode() {
        let vm = StorageViewModel(reddemCode: nil)

        XCTAssertNil(vm.redeemCodeFromUrl)
    }

    // MARK: - StorageViewModel Presentation Toggles

    func testViewModel_PresentationTogglesCanBeSet() {
        let vm = StorageViewModel()

        vm.addStorageIsPresented = true
        vm.giftStorageIsPresented = true
        vm.redeemStorageIspresented = true
        vm.showRedeemCodeView = true
        vm.showRedeemNotif = true
        vm.showError = true

        XCTAssertTrue(vm.addStorageIsPresented)
        XCTAssertTrue(vm.giftStorageIsPresented)
        XCTAssertTrue(vm.redeemStorageIspresented)
        XCTAssertTrue(vm.showRedeemCodeView)
        XCTAssertTrue(vm.showRedeemNotif)
        XCTAssertTrue(vm.showError)
    }

    // MARK: - StorageViewModel Space Properties

    func testViewModel_SpacePropertiesCanBeSet() {
        let vm = StorageViewModel()

        vm.spaceTotal = 10_737_418_240
        vm.spaceLeft = 5_368_709_120
        vm.spaceUsed = 5_368_709_120

        XCTAssertEqual(vm.spaceTotal, 10_737_418_240)
        XCTAssertEqual(vm.spaceLeft, 5_368_709_120)
        XCTAssertEqual(vm.spaceUsed, 5_368_709_120)
    }

    func testViewModel_SpaceRatioCanBeSet() {
        let vm = StorageViewModel()

        vm.spaceRatio = 0.5
        XCTAssertEqual(vm.spaceRatio, 0.5, accuracy: 0.001)
    }

    func testViewModel_ReadableSpaceCanBeSet() {
        let vm = StorageViewModel()

        vm.spaceTotalReadable = "10 GB"
        vm.spaceLeftReadable = "5 GB"
        vm.spaceUsedReadable = "5 GB"

        XCTAssertEqual(vm.spaceTotalReadable, "10 GB")
        XCTAssertEqual(vm.spaceLeftReadable, "5 GB")
        XCTAssertEqual(vm.spaceUsedReadable, "5 GB")
    }

    // MARK: - StorageViewModel Redeem Amount

    func testViewModel_RedeemAmountCanBeSet() {
        let vm = StorageViewModel()

        vm.redeemAmmountInt = 5
        XCTAssertEqual(vm.redeemAmmountInt, 5)
    }

    func testViewModel_RedeemAmountConvertedCanBeSet() {
        let vm = StorageViewModel()

        vm.redeemAmmountConverted = "5 GB"
        XCTAssertEqual(vm.redeemAmmountConverted, "5 GB")
    }

    // MARK: - StorageViewModel getStorageSpaceDetails

    func testViewModel_GetStorageSpaceDetails_NilAccount() {
        let vm = StorageViewModel()
        vm.accountData = nil

        vm.getStorageSpaceDetails()

        XCTAssertEqual(vm.spaceTotal, 0)
        XCTAssertEqual(vm.spaceLeft, 0)
        XCTAssertEqual(vm.spaceUsed, 0)
    }

    // MARK: - StorageViewModel addInTotalSpace

    func testViewModel_AddInTotalSpace() {
        let vm = StorageViewModel()
        vm.spaceTotal = 1_073_741_824

        vm.addInTotalSpace(spaceToAdd: 1_073_741_824)

        XCTAssertEqual(vm.spaceTotal, 2_147_483_648)
    }

    // MARK: - StorageView Rendering

    func testStorageView_Renders() {
        let view = StorageView(viewModel: StateObject(wrappedValue: StorageViewModel()))
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testStorageView_RendersWithRedeemCode() {
        let view = StorageView(viewModel: StateObject(wrappedValue: StorageViewModel(reddemCode: "TEST")))
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
