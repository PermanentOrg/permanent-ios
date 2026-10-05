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
    var downloadButton: XCUIElement { menuItem("download") }
    var copyButton: XCUIElement { menuItem("copy") }
    var moveButton: XCUIElement { menuItem("move") }
    var deleteButton: XCUIElement { menuItem("delete") }
    var unshareButton: XCUIElement { menuItem("unshare") }
    var renameButton: XCUIElement { menuItem("rename") }
    var publishButton: XCUIElement { menuItem("publish") }
    var shareLinkButton: XCUIElement { menuItem("shareToPermanent") }
    var shareToOtherButton: XCUIElement { menuItem("shareToAnotherApp") }
    var editMetadataButton: XCUIElement { menuItem("editMetadata") }

    init(app: XCUIApplication) {
        self.app = app
    }

    /// A row by its fixed name. Its title shows up as a button or as text, depending on the iOS version.
    private func menuItem(_ type: String) -> XCUIElement {
        app.descendants(matching: .any)["fileMenuItem.\(type)"]
    }
}
