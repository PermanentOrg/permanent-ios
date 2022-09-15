//
//  DeleteAlertPage.swift
//  PermanentUITests
//
//  Created by Vlad Alexandru Rusu on 09.09.2022.
//

import Foundation
import XCTest

class DeleteAlertPage {
    let app: XCUIApplication
    
    var cancelButton: XCUIElement { app.buttons["Cancel"] }
    var deleteButton: XCUIElement { app.buttons["Delete"] }
    
    init(app: XCUIApplication) {
        self.app = app
    }
}
