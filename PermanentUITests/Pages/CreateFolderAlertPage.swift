//
//  CreateFolderAlertPage.swift
//  PermanentUITests
//
//  Created by Vlad Alexandru Rusu on 09.09.2022.
//

import Foundation
import XCTest

class CreateFolderAlertPage {
    let app: XCUIApplication
    
    var textField: XCUIElement { app.textFields["Folder Name"] }
    var cancelButton: XCUIElement { app.buttons["Cancel"] }
    var createButton: XCUIElement { app.buttons["Create"] }
    
    init(app: XCUIApplication) {
        self.app = app
    }
}

