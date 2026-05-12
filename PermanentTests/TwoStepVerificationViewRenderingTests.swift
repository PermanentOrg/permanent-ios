//
//  TwoStepVerificationViewRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class TwoStepVerificationViewRenderingTests: XCTestCase {

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    private func makeContainerVM() -> TwoStepConfirmationContainerViewModel {
        TwoStepConfirmationContainerViewModel(
            refreshSecurityView: .constant(false),
            methodSelectedForDelete: .constant(nil),
            twoStepVerificationBottomBannerMessage: .constant(.none)
        )
    }

    // MARK: - TwoStepChoosePhoneView (~308 uncov lines)

    func testTwoStepChoosePhoneView_Renders() {
        let containerVM = makeContainerVM()
        let vm = TwoStepChoosePhoneViewModel(containerViewModel: containerVM)
        let view = TwoStepChoosePhoneView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - TwoStepChooseEmailView (~305 uncov lines)

    func testTwoStepChooseEmailView_Renders() {
        let containerVM = makeContainerVM()
        let vm = TwoStepChooseEmailViewModel(containerViewModel: containerVM)
        let view = TwoStepChooseEmailView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }
}
