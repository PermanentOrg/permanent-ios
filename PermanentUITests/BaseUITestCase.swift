//
//  BaseUITestCase.swift
//  PermanentUITests
//
//  Created by Vlad Alexandru Rusu on 08.09.2022.
//

import XCTest

class BaseUITestCase: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        app.launchArguments.append("--SkipOnboarding")
        app.launchArguments.append("--DiscardSession")
        app.launchArguments.append("--AddTextClearButton")
        app.launch()
        sleep(5)
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        addUIInterruptionMonitor(withDescription: "Auth Prompt") { (alert) -> Bool in
            if alert.staticTexts["“Permanent” Wants to Use “permanent.org” to Sign In"].exists ||
                alert.staticTexts["“Permanent” Wants to Use “fusionauth.io” to Sign In"].exists {
                alert.buttons["Continue"].tap()
                return true
            } else {
                return false
            }
        }
        
        addUIInterruptionMonitor(withDescription: "Push Notifications Prompt") { (alert) -> Bool in
            if alert.staticTexts["“Permanent” Would Like to Send You Notifications"].exists {
                alert.buttons["Allow"].tap()
                return true
            } else {
                return false
            }
        }
        
        addUIInterruptionMonitor(withDescription: "Photo Library Prompt") { (alert) -> Bool in
            if alert.staticTexts["“Permanent” Would Like to Access Your Photos"].exists {
                alert.buttons["Allow Access to All Photos"].tap()
                return true
            } else {
                return false
            }
        }
        
        let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.2))
        coordinate.tap()
        sleep(3)
        coordinate.tap()
        sleep(3)
        coordinate.tap()
        sleep(3)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}
