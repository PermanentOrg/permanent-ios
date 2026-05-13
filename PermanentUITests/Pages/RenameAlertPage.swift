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
    
    var textField: XCUIElement {
        let identified = app.textFields["renameTextField"]
        if identified.exists { return identified }
        // Legacy UIKit alert fallback.
        let legacy = app.textFields["Name"]
        if legacy.exists { return legacy }
        return identified
    }
    var cancelButton: XCUIElement { app.buttons["Cancel"] }
    var renameButton: XCUIElement { app.buttons["Rename"] }
    
    init(app: XCUIApplication) {
        self.app = app
    }
}
