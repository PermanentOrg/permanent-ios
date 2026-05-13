//
//  ShareManagementPage.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 13.05.2026.
//

import Foundation
import XCTest

class ShareManagementPage {
    let app: XCUIApplication

    var createLinkCard: XCUIElement { app.staticTexts["Create link to share"] }
    var settingsButton: XCUIElement { app.buttons["shareLinkSettingsButton"] }
    var copyButton: XCUIElement { app.buttons["shareLinkCopyButton"] }
    var shareItemTitle: XCUIElement { app.staticTexts["Share item"] }

    // Link Settings
    var linkSettingsTitle: XCUIElement { app.staticTexts["Link settings"] }
    var generalAccessRow: XCUIElement { app.buttons["generalAccessRow"].firstMatch }
    var restrictedOption: XCUIElement { app.staticTexts["Restricted"] }
    var revokeLinkButton: XCUIElement { app.staticTexts["Revoke link"] }
    var saveButton: XCUIElement { app.buttons["Save"] }
    var doneButton: XCUIElement { app.buttons["Done"] }
    var cancelButton: XCUIElement { app.buttons["Cancel"] }

    // General Access
    var generalAccessTitle: XCUIElement { app.staticTexts["General access"] }

    // Revoke confirmation
    var confirmRevokeButton: XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == 'Revoke link'")).element(boundBy: 0)
    }

    init(app: XCUIApplication) {
        self.app = app
    }

    func waitForShareItemView() {
        XCTAssertTrue(shareItemTitle.waitForExistence(timeout: 10))
    }

    func createLink() {
        XCTAssertTrue(createLinkCard.waitForExistence(timeout: 10))
        createLinkCard.tap()
        XCTAssertTrue(linkSettingsTitle.waitForExistence(timeout: 30))
    }

    func openLinkSettings() {
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10))
        settingsButton.tap()
        XCTAssertTrue(linkSettingsTitle.waitForExistence(timeout: 10))
    }

    func changeToRestricted() {
        XCTAssertTrue(generalAccessRow.waitForExistence(timeout: 10))
        generalAccessRow.tap()
        XCTAssertTrue(generalAccessTitle.waitForExistence(timeout: 10))
        XCTAssertTrue(restrictedOption.waitForExistence(timeout: 10))
        restrictedOption.tap()
        sleep(3)
    }

    func saveSettings() {
        if saveButton.waitForExistence(timeout: 5) {
            saveButton.tap()
        } else if doneButton.waitForExistence(timeout: 5) {
            doneButton.tap()
        }
        sleep(3)
    }

    func revokeLink() {
        app.swipeUp()
        XCTAssertTrue(revokeLinkButton.waitForExistence(timeout: 10))
        revokeLinkButton.tap()
        XCTAssertTrue(confirmRevokeButton.waitForExistence(timeout: 10))
        confirmRevokeButton.tap()
        sleep(3)
    }
}
