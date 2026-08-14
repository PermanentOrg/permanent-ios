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
        app.launchArguments.append("--SkipOnboarding")
        app.launchArguments.append("--DiscardSession")
        app.launchArguments.append("--AddTextClearButton")

        // Pass `TEST_RUNNER_STELA_NAV=1` or `=0` to xcodebuild to force V2 or V1; it arrives here as
        // `STELA_NAV` and is forwarded as a launch arg, so one suite covers both paths.
        if let stelaNav = ProcessInfo.processInfo.environment["STELA_NAV"] {
            app.launchArguments.append(stelaNav == "0" ? "--forceLegacyNavigation" : "--forceStelaNavigation")
        }

        app.launch()
        sleep(5)
        continueAfterFailure = false

        addUIInterruptionMonitor(withDescription: "Push Notifications Prompt") { (alert) -> Bool in
            if alert.buttons["Allow"].exists {
                alert.buttons["Allow"].tap()
                return true
            }
            return false
        }

        addUIInterruptionMonitor(withDescription: "Photo Library Prompt") { (alert) -> Bool in
            if alert.buttons["Allow Access to All Photos"].exists {
                alert.buttons["Allow Access to All Photos"].tap()
                return true
            }
            return false
        }

        addUIInterruptionMonitor(withDescription: "Save Password Prompt") { (alert) -> Bool in
            if alert.buttons["Not Now"].exists {
                alert.buttons["Not Now"].tap()
                return true
            }
            return false
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
    }
}
