//
//  SettingsMenuNavigationUITests.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 13.05.2026.
//

import XCTest

/// Walks every Settings menu option, including the Storage and Login & Security sub-options, to
/// exercise each destination's load path. Coverage of reachable code, not deep interaction.
class SettingsMenuNavigationUITests: BaseUITestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
    }

    func testWalkThroughAllSettingsOptions() throws {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password

        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)

        let privateFilesPage = PrivateFilesPage(app: app, testCase: self)
        privateFilesPage.waitForExistence()

        // Account.
        visit(privateFilesPage: privateFilesPage) { settings in
            settings.accountOption.tap()
        }

        // Storage + its 3 sub-options.
        visit(privateFilesPage: privateFilesPage) { settings in
            settings.storageOption.tap()
            sleep(3)

            walkSubOption(settings.storageAddOption)
            walkSubOption(settings.storageGiftOption)
            walkSubOption(settings.storageRedeemOption)
        }

        // My archives.
        visit(privateFilesPage: privateFilesPage) { settings in
            settings.myArchivesOption.tap()
        }

        // Invitations.
        visit(privateFilesPage: privateFilesPage) { settings in
            settings.invitationsOption.tap()
        }

        // Activity feed.
        visit(privateFilesPage: privateFilesPage) { settings in
            settings.activityFeedOption.tap()
        }

        // Login & Security + its 2 sub-options.
        visit(privateFilesPage: privateFilesPage) { settings in
            settings.loginAndSecurityOption.tap()
            sleep(3)

            walkSubOption(settings.securityChangePasswordOption)
            walkSubOption(settings.securityTwoStepOption)
        }

        // Legacy Planning.
        visit(privateFilesPage: privateFilesPage) { settings in
            settings.legacyPlanningOption.tap()
        }

        // Sign out via the standard right side menu logout flow.
        privateFilesPage.waitForExistence()
        privateFilesPage.toggleRightSideMenu()

        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
        sleep(2)

        loginPage.waitForExistence()
    }

    /// Opens Settings, runs the action, then dismisses whatever ends up on top. Settings closes as
    /// soon as a top-level option is tapped, so each visit is independent.
    private func visit(privateFilesPage: PrivateFilesPage,
                       _ tapOption: (SettingsMenuPage) -> Void) {
        privateFilesPage.toggleRightSideMenu()

        let settingsMenu = SettingsMenuPage(app: app)
        settingsMenu.waitForExistence()

        tapOption(settingsMenu)

        // Give the destination time to present and load.
        sleep(3)

        // Dismiss the destination modal so we end up back at Private Files.
        settingsMenu.dismissCurrentScreen()
        sleep(2)
    }

    /// Taps a sub-option and immediately dismisses the screen it opens, returning to the parent menu
    /// ready for the next one.
    private func walkSubOption(_ option: XCUIElement) {
        XCTAssertTrue(option.waitForExistence(timeout: 10),
                      "Expected sub-option to be visible: \(option)")
        option.tap()
        sleep(3)

        let settingsMenu = SettingsMenuPage(app: app)
        settingsMenu.dismissCurrentScreen()
        sleep(1)
    }
}
