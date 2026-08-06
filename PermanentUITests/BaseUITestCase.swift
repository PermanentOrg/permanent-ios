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

        // Stela V2 A/B: pass `TEST_RUNNER_STELA_NAV=1` (force V2) or `=0` (force V1 failsafe)
        // to xcodebuild; it reaches the runner here as `STELA_NAV`, and we forward it as a
        // launch arg so the same UI test can run against both navigation paths. Absent → the
        // build default, which is now V1 in every build (see `FeatureFlags.useStelaNavigation`);
        // pass `=1` explicitly to exercise the deferred V2 epic.
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
