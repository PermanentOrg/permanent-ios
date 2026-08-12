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
    var stateOverlay: XCUIElement {
        app.otherElements["imagePreviewStateOverlay"]
    }
    var stateMessage: XCUIElement {
        app.staticTexts["imagePreviewStateMessage"]
    }

    init(app: XCUIApplication) {
        self.app = app
    }

    func waitForExistence() {
        // The preview nests a page controller inside its own navigation controller, so the close
                // button being reachable is the stable signal that it rendered.
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

    // MARK: - Image preview states

    /// Waits for the S6 "load failed" card.
    func waitForLoadFailedState() {
        XCTAssertTrue(stateMessage.waitForExistence(timeout: 15))
        XCTAssertTrue(stateMessage.label.contains("Couldn't load image."))
    }

    /// Waits for the S7 offline card.
    func waitForOfflineState() {
        XCTAssertTrue(stateMessage.waitForExistence(timeout: 15))
        XCTAssertTrue(stateMessage.label.contains("You're offline."))
    }

    /// Taps the overlay, which triggers the retry action.
    func tapRetry() {
        XCTAssertTrue(stateOverlay.waitForExistence(timeout: 5))
        stateOverlay.tap()
    }

    /// Waits until the loading/error overlay is gone — the image rendered fully (S4).
    func waitForImageLoaded(timeout: TimeInterval = 20) {
        let gone = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: gone, object: stateMessage)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: timeout), .completed,
                       "Expected the state overlay message to disappear once the full image loaded")
    }
}
