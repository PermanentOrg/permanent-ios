//
//  SearchFilesPage.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 13.05.2026.
//

import Foundation
import XCTest

class SearchFilesPage {
    let app: XCUIApplication

    var searchBar: XCUIElement {
        let identified = app.searchFields["filesSearchBar"]
        if identified.exists { return identified }
        let byPlaceholder = app.searchFields["Search Files"]
        if byPlaceholder.exists { return byPlaceholder }
        return app.searchFields.firstMatch
    }
    var closeButton: XCUIElement {
        app.navigationBars.buttons["xmark"]
    }
    var screenTitle: XCUIElement {
        app.navigationBars["Search"]
    }

    init(app: XCUIApplication) {
        self.app = app
    }

    func waitForExistence() {
        XCTAssertTrue(searchBar.waitForExistence(timeout: 10))
    }

    func typeQuery(_ query: String) {
        XCTAssertTrue(searchBar.waitForExistence(timeout: 10))
        searchBar.tap()
        searchBar.typeText(query)
        sleep(3)
    }

    func clearText() {
        let clearButton = searchBar.buttons["Clear text"]
        if clearButton.exists {
            clearButton.tap()
        }
    }

    func assertResultExists(named name: String) {
        let cell = app.collectionViews.cells.containing(.staticText, identifier: name).firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 15), "Expected search result '\(name)' to appear")
    }

    func close() {
        if closeButton.exists {
            closeButton.tap()
        } else {
            app.navigationBars.buttons.firstMatch.tap()
        }
        sleep(2)
    }
}
