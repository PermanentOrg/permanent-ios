//
//  PublicProfilePage.swift
//  PermanentUITests
//
//  Created by Vlad Alexandru Rusu on 15.11.2022.
//

import Foundation
import XCTest

class PublicProfilePage {
    let app: XCUIApplication
    
    var aboutHeader: XCUIElement { app.collectionViews.otherElements.containing(.staticText, identifier: "About").firstMatch }
    var aboutEditButton: XCUIElement { aboutHeader.staticTexts["Edit"] }
        
    var personInformationHeader: XCUIElement { app.collectionViews.otherElements.containing(.staticText, identifier: "Person Information").firstMatch }
    var personInformationEditButton: XCUIElement { personInformationHeader.staticTexts["Edit"] }

    var onlinePresenceHeader: XCUIElement { app.collectionViews.otherElements.containing(.staticText, identifier: "Online Presence").firstMatch }
    var onlinePresenceEditButton: XCUIElement { onlinePresenceHeader.staticTexts["Edit"] }
    
    var milestonesHeader: XCUIElement { app.collectionViews.otherElements.containing(.staticText, identifier: "Milestones").firstMatch }
    var milestonesEditButton: XCUIElement { milestonesHeader.staticTexts["Edit"] }
    
    init(app: XCUIApplication) {
        self.app = app
    }
}
