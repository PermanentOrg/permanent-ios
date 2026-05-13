//
//  FileDetailsPage.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 13.05.2026.
//

import Foundation
import XCTest

class FileDetailsPage {
    let app: XCUIApplication

    var closeButton: XCUIElement {
        app.buttons["fileDetailsCloseButton"]
    }
    var shareButton: XCUIElement {
        app.buttons["fileDetailsShareButton"]
    }
    var segmentedControl: XCUIElement {
        app.segmentedControls["fileDetailsSegmentedControl"]
    }
    var infoSegment: XCUIElement {
        segmentedControl.buttons["Info"]
    }
    var detailsSegment: XCUIElement {
        segmentedControl.buttons["Details"]
    }

    init(app: XCUIApplication) {
        self.app = app
    }

    func waitForExistence() {
        XCTAssertTrue(closeButton.waitForExistence(timeout: 15))
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 10))
    }

    func selectInfoTab() {
        XCTAssertTrue(infoSegment.waitForExistence(timeout: 10))
        infoSegment.tap()
        sleep(1)
    }

    func selectDetailsTab() {
        XCTAssertTrue(detailsSegment.waitForExistence(timeout: 10))
        detailsSegment.tap()
        sleep(1)
    }

    func close() {
        XCTAssertTrue(closeButton.waitForExistence(timeout: 10))
        closeButton.tap()
        sleep(2)
    }
}
