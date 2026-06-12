//
//  PhotoLibraryPage.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 08.08.2022.
//

import Foundation
import XCTest

class PhotoLibraryPage {
    let app: XCUIApplication

    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
    }

    func waitForExistence() {
        sleep(1)
        app.tap()
        sleep(1)

        let photosButton = app.buttons["Photos"]
        XCTAssertTrue(photosButton.waitForExistence(timeout: 30))
    }

    func uploadFirstPhoto() {
        sleep(2)

        let dismissBanner = app.buttons["Dismiss"]
        if dismissBanner.waitForExistence(timeout: 2) {
            dismissBanner.tap()
            sleep(1)
        }

        let firstPhoto = app.images.element(boundBy: 0)
        XCTAssertTrue(firstPhoto.waitForExistence(timeout: 10))
        firstPhoto.tap()

        let addButton = app.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
    }
}
