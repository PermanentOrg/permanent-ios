//
//  RootNavigationControllerTitleTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 14.10.2026.
//

import Testing
import UIKit
@testable import Permanent

/// The files screen styles its bar once, and the root container restyles the bar after every modal.
/// Both must give the title the same font, or the title shrinks when a file preview closes.
@MainActor
struct RootNavigationControllerTitleTests {
    @Test("The bar title keeps its font after a modal closes")
    func titleFontSurvivesModalDismissal() {
        let screen = MainViewController()
        let container = RootNavigationController(viewController: screen)
        screen.styleNavBar()
        let atStart = titleFont(of: container)

        container.viewWillAppear(false)

        #expect(atStart == TextFontStyle.navigationBarTitle.font)
        #expect(titleFont(of: container) == atStart)
    }

    private func titleFont(of container: UINavigationController) -> UIFont? {
        container.navigationBar.standardAppearance.titleTextAttributes[.font] as? UIFont
    }
}
