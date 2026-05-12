//
//  FileMenuPage.swift
//  PermanentUITests
//
//  Created by Vlad Alexandru Rusu on 09.09.2022.
//

import Foundation
import XCTest

class FileMenuPage {
    let app: XCUIApplication
    
    var closeButton: XCUIElement { app.buttons["fileMenuCloseButton"] }
    var downloadButton: XCUIElement { app.staticTexts["Save"] }
    var copyButton: XCUIElement { app.staticTexts["Copy to another folder"] }
    var moveButton: XCUIElement { app.staticTexts["Move to another folder"] }
    var deleteButton: XCUIElement { app.staticTexts["Delete"] }
    var unshareButton: XCUIElement { app.staticTexts["Leave share"] }
    var renameButton: XCUIElement { app.staticTexts["Rename"] }
    var publishButton: XCUIElement { app.staticTexts["Publish on the web"] }
    var shareLinkButton: XCUIElement { app.staticTexts["Share and manage access"] }
    var shareToOtherButton: XCUIElement { app.staticTexts["Save or send a copy"] }
    var editMetadataButton: XCUIElement { app.staticTexts["Edit Metadata"] }
    
    init(app: XCUIApplication) {
        self.app = app
    }
}
