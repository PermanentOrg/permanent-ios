//
//  PhotoLibraryPage.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 08.08.2022.
//

import Foundation
import XCTest

class PhotoLibraryPage {
    let app: XCUIApplication
    
    var navigationBar: XCUIElement {
        app.navigationBars["Recents"]
    }
    var firstPhotoFromCollectionView: XCUIElement {
        app.collectionViews.children(matching: .cell).element(boundBy: 5).children(matching: .other).element
    }
    var uploadOneElement: XCUIElement {
        app.toolbars["Toolbar"].buttons["Upload 1 items"]
    }
    
    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
    }
    
    func waitForExistence() {
        // Sleep and tap just in case the UIInterruptionMonitor needs to be triggered.
        // The monitor needs at least one action to be interrupted after it was sent to the app
        sleep(1)
        app.tap()
        
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 50))
    }
    
    func uploadFirstPhoto() {
        XCTAssertTrue(firstPhotoFromCollectionView.waitForExistence(timeout: 5))
        firstPhotoFromCollectionView.tap()
        
        XCTAssertTrue(uploadOneElement.waitForExistence(timeout: 5))
        uploadOneElement.tap()
    }
}
