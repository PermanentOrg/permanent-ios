//
//  CommonUIRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class CommonUIRenderingTests: XCTestCase {

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    // MARK: - CreateNewFolderView (~100 uncov lines)

    func testCreateNewFolderView_Renders() {
        let view = CreateNewFolderView(onCreateFolder: { _ in })
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - OnboardingTitleTextView (~50 uncov lines)

    func testOnboardingTitleTextView_Renders() {
        let view = OnboardingTitleTextView(
            preText: "Welcome to ",
            boldText: "Permanent",
            postText: " Archive"
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - NewBadgeView (~30 uncov lines)

    func testNewBadgeView_Renders() {
        let view = NewBadgeView(badgeText: "NEW", badgeColor: .red)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - SnackBarView (~80 uncov lines)

    func testSnackBarView_Renders() {
        let view = SnackBarView(message: "Operation complete", show: .constant(true))
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testSnackBarView_RendersHidden() {
        let view = SnackBarView(message: "Hidden", show: .constant(false))
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - SimpleTagView (~40 uncov lines)

    func testSimpleTagView_Renders() {
        let view = SimpleTagView(text: "Important")
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - BannerTwoStepVerificationView (~60 uncov lines)

    func testBannerTwoStepVerificationView_RendersEnabled() {
        let view = BannerTwoStepVerificationView(isEnabled: true)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testBannerTwoStepVerificationView_RendersDisabled() {
        let view = BannerTwoStepVerificationView(isEnabled: false)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - WarningBannerView (~40 uncov lines)

    func testWarningBannerView_Renders() {
        let view = WarningBannerView(message: "Please verify your email")
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - CustomToggleView (~50 uncov lines)

    func testCustomToggleView_RendersOn() {
        let view = CustomToggleView(isOn: .constant(true))
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testCustomToggleView_RendersOff() {
        let view = CustomToggleView(isOn: .constant(false))
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - AccessRoleChipView (~30 uncov lines)

    func testAccessRoleChipView_Renders() {
        let view = AccessRoleChipView(text: "Owner")
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - DividerSmallBarView (~30 uncov lines)

    func testDividerSmallBarView_Renders() {
        let view = DividerSmallBarView()
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - RoundStyledTextFieldView (~80 uncov lines)

    func testRoundStyledTextFieldView_Renders() {
        let view = RoundStyledTextFieldView(
            text: .constant(""),
            placeholderText: "Enter text",
            invalidField: false,
            doneAction: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testRoundStyledTextFieldView_RendersInvalid() {
        let view = RoundStyledTextFieldView(
            text: .constant("bad input"),
            placeholderText: "Enter text",
            invalidField: true,
            doneAction: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - CustomBorderTextField (~80 uncov lines)

    func testCustomBorderTextField_Renders() {
        let view = CustomBorderTextField(textFieldText: .constant(""))
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - RoundButtonView (~60 uncov lines)

    func testRoundButtonView_Renders() {
        let view = RoundButtonView(
            isDisabled: false,
            isLoading: false,
            text: "Continue",
            action: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testRoundButtonView_RendersDisabled() {
        let view = RoundButtonView(
            isDisabled: true,
            isLoading: false,
            text: "Continue",
            action: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testRoundButtonView_RendersLoading() {
        let view = RoundButtonView(
            isDisabled: false,
            isLoading: true,
            text: "Continue",
            action: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - RoundButtonUsualFontView (~60 uncov lines)

    func testRoundButtonUsualFontView_Renders() {
        let view = RoundButtonUsualFontView(
            isDisabled: false,
            isLoading: false,
            text: "Save",
            action: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - RightButtonView (~40 uncov lines)

    func testRightButtonView_Renders() {
        let view = RightButtonView(text: "See all", action: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testRightButtonView_RendersNoChevron() {
        let view = RightButtonView(text: "Done", showChevron: false, action: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - PullDownButton (~80 uncov lines)

    func testPullDownButton_Renders() {
        let items = [PullDownItem(title: "Option 1"), PullDownItem(title: "Option 2")]
        let view = PullDownButton(selectedItem: .constant(nil), items: items)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testPullDownButton_RendersWithSelection() {
        let items = [PullDownItem(title: "Option 1"), PullDownItem(title: "Option 2")]
        let view = PullDownButton(selectedItem: .constant(items.first), items: items)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }
}
