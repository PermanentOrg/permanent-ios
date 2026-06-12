//
//  PublicProfileAboutPage.swift
//  PermanentUITests
//
//  Created by Vlad Alexandru Rusu on 15.11.2022.
//

import Foundation
import XCTest

class PublicProfileAboutPage {
    let app: XCUIApplication
    
    var archiveNameElement: XCUIElement { app.textFields["archiveNameTextField"] }
    var shortDescriptionElement: XCUIElement { app.textFields["shortDescriptionTextField"] }
    var longDescriptionElement: XCUIElement { app.textViews["longDescriptionTextView"] }
    var doneButton: XCUIElement { app.navigationBars.buttons["Done"].firstMatch }

    init(app: XCUIApplication) {
        self.app = app
    }

    func addShortDescription() -> String {
        let shortUUID = UUID().uuidString
        shortDescriptionElement.tap()
        shortDescriptionElement.selectAndDeleteText(inApp: app)
        shortDescriptionElement.tap()
        shortDescriptionElement.typeText(shortUUID)

        return shortUUID
    }

    func addLongDescription() -> String {
        let longUUID = UUID().uuidString
        longDescriptionElement.tap()
        longDescriptionElement.clearTextView()
        longDescriptionElement.typeText(longUUID)

        return longUUID
    }
}
