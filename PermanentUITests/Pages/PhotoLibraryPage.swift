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
        let photosButton = app.buttons["Photos"]
        XCTAssertTrue(photosButton.waitForExistence(timeout: 30))
        // A tap lets a permission prompt's handler run; the selected Photos tab picks no photo, a tap mid-screen can.
        photosButton.tap()
    }

    func uploadFirstPhoto() {
        sleep(2)

        // The picker's first-run card closes with "Dismiss" or "Close", depending on the iOS version.
        let firstRunCard = app.buttons.matching(NSPredicate(format: "label IN {'Dismiss', 'Close'}")).firstMatch
        if firstRunCard.waitForExistence(timeout: 2) {
            firstRunCard.tap()
            sleep(1)
        }

        // Only the picker's photos have a label that starts with "Photo"; the app's own images sit under the picker.
        let firstPhoto = app.images.matching(NSPredicate(format: "label BEGINSWITH 'Photo'")).firstMatch
        XCTAssertTrue(firstPhoto.waitForExistence(timeout: 10))
        // iOS 26 reports the picker's photos as not hittable while they are on screen, so tap the photo's centre.
        firstPhoto.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let addButton = app.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        XCTAssertTrue(addButton.wait(for: \.isEnabled, toEqual: true, timeout: 5), "no photo was picked")
        addButton.tap()
    }
}
