//
//  PublicProfilePage.swift
//  PermanentUITests
//
//  Created by Vlad Alexandru Rusu on 15.11.2022.
//

import Foundation
import XCTest

class PublicProfilePage {
    let app: XCUIApplication
    
    var aboutEditButton: XCUIElement { app.buttons["archiveInformationEditButton"] }
    var personInformationEditButton: XCUIElement { app.buttons["personInformationEditButton"] }
    var onlinePresenceEditButton: XCUIElement { app.buttons["onlinePresenceEditButton"] }
    var milestonesEditButton: XCUIElement { app.buttons["milestonesEditButton"] }

    init(app: XCUIApplication) {
        self.app = app
    }

    /// The profile slides in after the side menu closes, and a tap during the slide misses the button.
    func tapEdit(_ editButton: XCUIElement) {
        bringOnScreen(editButton)
        XCTAssertTrue(editButton.waitForExistence(timeout: 10))
        XCTAssertTrue(editButton.waitUntilSettled(timeout: 10), "the Edit button kept moving")
        editButton.tap()
    }

    /// Lower sections load only once they scroll into view, and a swipe can leave a header above the screen.
    private func bringOnScreen(_ element: XCUIElement) {
        for _ in 0..<5 where !(element.exists && element.isHittable) {
            if element.exists && element.frame.midY < app.frame.midY {
                app.swipeDown()
            } else {
                app.swipeUp()
            }
        }
    }
}
