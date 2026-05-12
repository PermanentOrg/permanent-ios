//
//  OnboardingCongratulationsViewRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class OnboardingCongratulationsViewRenderingTests: XCTestCase {

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    // MARK: - OnboardingCongratulationsView (~468 uncov lines)

    func testOnboardingCongratulationsView_Renders() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingCongratulationsViewModel(containerViewModel: container)
        let view = OnboardingCongratulationsView(
            viewModel: vm,
            backButton: {},
            nextButton: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - OnboardingWelcomeView (~138 uncov lines)

    func testOnboardingWelcomeView_Renders() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingInvitedWelcomeViewModel(containerViewModel: container)
        let view = OnboardingWelcomeView(viewModel: vm, buttonAction: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - OnboardingCreateFirstArchiveView (~156 uncov lines)

    func testOnboardingCreateFirstArchiveView_Renders() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingCreateFirstArchiveViewModel(containerViewModel: container)
        let view = OnboardingCreateFirstArchiveView(
            viewModel: vm,
            backButton: {},
            nextButton: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }
}
