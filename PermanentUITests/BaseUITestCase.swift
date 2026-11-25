//
//  BaseUITestCase.swift
//  PermanentUITests
//
//  Created by Vlad Alexandru Rusu on 08.09.2022.
//

import XCTest

class BaseUITestCase: XCTestCase {
    let app = XCUIApplication()

    /// The staging account this run names in its environment, so simulators testing at once never share one.
    var account: UITestCredentials {
        let environment = ProcessInfo.processInfo.environment
        guard let username = environment["UI_TEST_USERNAME"], !username.isEmpty,
              let password = environment["UI_TEST_PASSWORD"], !password.isEmpty else {
            return uiTestCredentials
        }
        return UITestCredentials(username: username, password: password)
    }

    override func setUpWithError() throws {
        app.launchArguments.append("--SkipOnboarding")
        app.launchArguments.append("--DiscardSession")
        app.launchArguments.append("--AddTextClearButton")

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
