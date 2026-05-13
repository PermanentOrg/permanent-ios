//
//  FilePreviewPage.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 13.05.2026.
//

import Foundation
import XCTest

class FilePreviewPage {
    let app: XCUIApplication

    var closeButton: XCUIElement {
        app.buttons["filePreviewCloseButton"]
    }
    var infoButton: XCUIElement {
        app.buttons["filePreviewInfoButton"]
    }
    var shareButton: XCUIElement {
        app.buttons["filePreviewShareButton"]
    }

    init(app: XCUIApplication) {
        self.app = app
    }

    func waitForExistence() {
        // The preview hosts a UIPageViewController and lives inside a
        // FilePreviewNavigationController; verify the close button is reachable
        // as a stable signal that the screen rendered.
        XCTAssertTrue(closeButton.waitForExistence(timeout: 15))
    }

    func openDetails() {
        XCTAssertTrue(infoButton.waitForExistence(timeout: 10))
        infoButton.tap()
        sleep(2)
    }

    func close() {
        XCTAssertTrue(closeButton.waitForExistence(timeout: 10))
        closeButton.tap()
        sleep(2)
    }
}
