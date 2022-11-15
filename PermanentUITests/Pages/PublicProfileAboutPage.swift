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
    
    var shortDescriptionElement: XCUIElement { app.textFields.firstMatch }
    var longDescriptionElement: XCUIElement { app.textViews.firstMatch }
    var doneButton: XCUIElement { app.navigationBars.buttons["Done"].firstMatch }
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    func addShortDescription() -> String {
        let shortUUID = UUID().uuidString
        shortDescriptionElement.selectAndDeleteText(inApp: app)
        shortDescriptionElement.typeText(shortUUID)
        
        return shortUUID
    }
    
    func addLongDescription() -> String {
        let longUUID = UUID().uuidString
        longDescriptionElement.clearTextView()
        longDescriptionElement.typeText(longUUID)
        
        return longUUID
    }
}
