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
    
    var doneButton: XCUIElement { app.buttons["Done"] }
    
    var downloadButton: XCUIElement { app.otherElements["Download to device"] }
    var copyButton: XCUIElement { app.otherElements["Copy"] }
    var moveButton: XCUIElement { app.otherElements["Move to another location"] }
    var deleteButton: XCUIElement { app.otherElements["Delete"] }
    var unshareButton: XCUIElement { app.otherElements["Unshare"] }
    var renameButton: XCUIElement { app.otherElements["Rename"] }
    var publishButton: XCUIElement { app.otherElements["Publish"] }
    var getLinkButton: XCUIElement { app.otherElements["Get Link"] }
    var shareLinkButton: XCUIElement { app.otherElements["Share link via Permanent"] }
    var manageLinkButton: XCUIElement { app.otherElements["Share management"] }
    var shareToOtherButton: XCUIElement { app.otherElements["Share to Another App"] }
    
    init(app: XCUIApplication) {
        self.app = app
    }
}
