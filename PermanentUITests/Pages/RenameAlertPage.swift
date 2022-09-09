//
//  RenameAlertPage.swift
//  PermanentUITests
//
//  Created by Vlad Alexandru Rusu on 09.09.2022.
//

import Foundation
import XCTest

class RenameAlertPage {
    let app: XCUIApplication
    
    var textField: XCUIElement { app.textFields["Name"] }
    var cancelButton: XCUIElement { app.buttons["Cancel"] }
    var renameButton: XCUIElement { app.buttons["Rename"] }
    
    init(app: XCUIApplication) {
        self.app = app
    }
}
