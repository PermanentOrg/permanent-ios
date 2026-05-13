//
//  SettingsMenuPage.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 13.05.2026.
//

import Foundation
import XCTest

class SettingsMenuPage {
    let app: XCUIApplication

    var accountOption: XCUIElement {
        app.buttons["settingsAccountOption"]
    }
    var storageOption: XCUIElement {
        app.buttons["settingsStorageOption"]
    }
    var myArchivesOption: XCUIElement {
        app.buttons["settingsMyArchivesOption"]
    }
    var invitationsOption: XCUIElement {
        app.buttons["settingsInvitationsOption"]
    }
    var activityFeedOption: XCUIElement {
        app.buttons["settingsActivityFeedOption"]
    }
    var loginAndSecurityOption: XCUIElement {
        app.buttons["settingsLoginSecurityOption"]
    }
    var legacyPlanningOption: XCUIElement {
        app.buttons["settingsLegacyPlanningOption"]
    }

    // Sub-options inside the Storage screen.
    var storageAddOption: XCUIElement {
        app.buttons["storageAddOption"]
    }
    var storageGiftOption: XCUIElement {
        app.buttons["storageGiftOption"]
    }
    var storageRedeemOption: XCUIElement {
        app.buttons["storageRedeemOption"]
    }

    // Sub-options inside the Login & Security screen.
    var securityChangePasswordOption: XCUIElement {
        app.buttons["securityChangePasswordOption"]
    }
    var securityTwoStepOption: XCUIElement {
        app.buttons["securityTwoStepOption"]
    }

    init(app: XCUIApplication) {
        self.app = app
    }

    func waitForExistence() {
        XCTAssertTrue(accountOption.waitForExistence(timeout: 10))
    }

    /// Dismisses whichever destination is on top by tapping its top nav-bar
    /// back/close button. Every settings destination wires its back/close button
    /// with the shared `settingsContainerBackButton` identifier. When a
    /// sub-screen is presented on top of a parent (e.g. AddStorage on Storage),
    /// both back buttons exist in the hierarchy at once — we pick the
    /// hittable one (the topmost / visible).
    func dismissCurrentScreen() {
        let backButtons = app.buttons.matching(identifier: "settingsContainerBackButton")
        XCTAssertTrue(backButtons.element.waitForExistence(timeout: 15),
                      "Expected a 'settingsContainerBackButton' on the destination screen")

        // Dismiss the keyboard first if it's covering the back button.
        if app.keyboards.element.exists {
            app.swipeDown()
            sleep(1)
        }

        for index in 0 ..< backButtons.count {
            let candidate = backButtons.element(boundBy: index)
            if candidate.isHittable {
                candidate.tap()
                sleep(2)
                return
            }
        }

        // No back button reported hittable — tap the last one (the topmost in
        // z-order on most layouts) at its coordinate as a fallback.
        let last = backButtons.element(boundBy: backButtons.count - 1)
        last.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(2)
    }
}
