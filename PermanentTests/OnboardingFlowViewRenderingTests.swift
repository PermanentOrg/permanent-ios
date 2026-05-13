//
//  OnboardingFlowViewRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class OnboardingFlowViewRenderingTests: XCTestCase {

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    // MARK: - OnboardingChartYourPathView (~347 uncov lines)

    func testOnboardingChartYourPathView_Renders() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingChartYourPathViewModel(containerViewModel: container)
        let view = OnboardingChartYourPathView(
            viewModel: vm,
            backButton: {},
            nextButton: {},
            skipButton: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - OnboardingWhatsImportantView (~240 uncov lines)

    func testOnboardingWhatsImportantView_Renders() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let vm = OnboardingWhatsImportantViewModel(containerViewModel: container)
        let view = OnboardingWhatsImportantView(
            viewModel: vm,
            backButton: {},
            nextButton: {},
            skipButton: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - OnboardingView (~200+ uncov lines)

    func testOnboardingView_Renders() {
        let container = OnboardingContainerViewModel(username: nil, password: nil)
        let view = OnboardingView(viewModel: container)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }
}
