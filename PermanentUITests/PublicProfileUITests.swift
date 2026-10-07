//
//  PublicProfileUITests.swift
//  PermanentUITests
//
//  Created by Vlad Alexandru Rusu on 20.09.2022.
//

import XCTest

class PublicProfileUITests: BaseUITestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
    }
    
    func testAboutDescription() {
        navigateToPublicProfile()
        
        let profilePage = PublicProfilePage(app: app)
        profilePage.tapEdit(profilePage.aboutEditButton)

        let aboutPage = PublicProfileAboutPage(app: app)
        let shortUUID = aboutPage.addShortDescription()
        let longUUID = aboutPage.addLongDescription()
        
        aboutPage.doneButton.tap()
        
        app.collectionViews.otherElements.staticTexts["Show More"].tap()
        
        let shortDescriptionCell = app.collectionViews.cells.containing(.staticText, identifier: shortUUID).firstMatch
        XCTAssertTrue(shortDescriptionCell.waitForExistence(timeout: 5))
        
        let longDescriptionCell = app.collectionViews.cells.containing(.staticText, identifier: longUUID).firstMatch
        XCTAssertTrue(longDescriptionCell.waitForExistence(timeout: 5))

        profilePage.tapEdit(profilePage.aboutEditButton)
        XCTAssertTrue(aboutPage.shortDescriptionElement.waitUntilSettled(timeout: 10))
        aboutPage.shortDescriptionElement.tap()
        aboutPage.shortDescriptionElement.selectAndDeleteText(inApp: app)
        aboutPage.longDescriptionElement.tap()
        aboutPage.longDescriptionElement.clearTextView()
        aboutPage.doneButton.tap()
    }
    
    func testPersonInformation() {
        navigateToPublicProfile()
        
        let profilePage = PublicProfilePage(app: app)
        profilePage.tapEdit(profilePage.personInformationEditButton)
        
        let personInfoPage = PublicProfilePersonInfoPage(app: app)
        let fullNameUUID = personInfoPage.fillFullName()
        let nicknameUUID = personInfoPage.fillNickname()
        let genderUUID = personInfoPage.fillGender()
    
        let doneButton = app.navigationBars.buttons["Done"].firstMatch
        doneButton.tap()
        
        let fullNameCell = app.collectionViews.cells.containing(.staticText, identifier: fullNameUUID).firstMatch
        XCTAssertTrue(fullNameCell.waitForExistence(timeout: 5))
        
        let nicknameCell = app.collectionViews.cells.containing(.staticText, identifier: nicknameUUID).firstMatch
        XCTAssertTrue(nicknameCell.waitForExistence(timeout: 5))
        
        let genderCell = app.collectionViews.cells.containing(.staticText, identifier: genderUUID).firstMatch
        XCTAssertTrue(genderCell.waitForExistence(timeout: 5))

        profilePage.tapEdit(profilePage.personInformationEditButton)
        XCTAssertTrue(personInfoPage.fullNameTextField.waitUntilSettled(timeout: 10))
        personInfoPage.fullNameTextField.tap()
        personInfoPage.fullNameTextField.selectAndDeleteText(inApp: app)
        personInfoPage.nicknameTextField.tap()
        personInfoPage.nicknameTextField.selectAndDeleteText(inApp: app)
        personInfoPage.genderTextField.tap()
        personInfoPage.genderTextField.selectAndDeleteText(inApp: app)
        doneButton.tap()
    }
    
    func testOnlinePresence() {
        navigateToPublicProfile()
        
        app.swipeUp()

        let profilePage = PublicProfilePage(app: app)
        profilePage.tapEdit(profilePage.onlinePresenceEditButton)
        // The profile shows only the first rows, so this run's rows must be the only ones.
        removeLeftoverRows()

        app.buttons["Add Email"].tap()
        
        let emailUUID = UUID().uuidString
        let emailTextField = app.textFields.firstMatch
        emailTextField.selectAndDeleteText(inApp: app)
        emailTextField.tap()
        emailTextField.typeText(emailUUID)
        
        let addEmailDoneButton = app.navigationBars["Add Email"].buttons["Done"].firstMatch
        addEmailDoneButton.tap()
        
        let emailCell = app.tables.cells.containing(.staticText, identifier: emailUUID).firstMatch
        XCTAssertTrue(emailCell.waitForExistence(timeout: 5))
        
        app.buttons["Add Link"].tap()
        
        let linkUUID = UUID().uuidString
        let linkTextField = app.textFields.firstMatch
        linkTextField.selectAndDeleteText(inApp: app)
        linkTextField.tap()
        linkTextField.typeText(linkUUID)
        
        let addLinkDoneButton = app.navigationBars["Add Social Media"].buttons["Done"].firstMatch
        addLinkDoneButton.tap()
        
        let linkCell = app.tables.cells.containing(.staticText, identifier: linkUUID).firstMatch
        XCTAssertTrue(linkCell.waitForExistence(timeout: 5))
        
        let editPresenceDoneButton = app.navigationBars["Edit Online Presence"].buttons["Done"].firstMatch
        editPresenceDoneButton.tap()

        app.swipeUp()
        app.swipeUp()

        let emailCollectionCell = app.collectionViews.cells.containing(.staticText, identifier: emailUUID).firstMatch
        XCTAssertTrue(emailCollectionCell.waitForExistence(timeout: 5))

        let linkCollectionCell = app.collectionViews.cells.containing(.staticText, identifier: linkUUID).firstMatch
        XCTAssertTrue(linkCollectionCell.waitForExistence(timeout: 5))

        profilePage.tapEdit(profilePage.onlinePresenceEditButton)

        deleteRow(emailCell)
        deleteRow(linkCell)
    }
    
    func testMilestones() {
        navigateToPublicProfile()

        app.swipeUp()
        app.swipeUp()

        let profilePage = PublicProfilePage(app: app)
        profilePage.tapEdit(profilePage.milestonesEditButton)
        removeLeftoverRows()

        app.buttons["Add Milestone"].tap()

        let descriptionUUID = UUID().uuidString
        let descriptionElement = app.textViews.firstMatch
        descriptionElement.clearTextView()
        descriptionElement.typeText(descriptionUUID)

        let titleUUID = UUID().uuidString
        let titleTextField = app.textFields.firstMatch
        titleTextField.selectAndDeleteText(inApp: app)
        titleTextField.tap()
        titleTextField.typeText(titleUUID)

        let addMilestoneDoneButton = app.navigationBars["Add Milestone"].buttons["Done"].firstMatch
        addMilestoneDoneButton.tap()

        let milestoneCell = app.tables.cells.containing(.staticText, identifier: titleUUID).firstMatch
        XCTAssertTrue(milestoneCell.waitForExistence(timeout: 5))

        let editMilestonesDoneButton = app.navigationBars["Edit Milestones"].buttons["Done"].firstMatch
        editMilestonesDoneButton.tap()

        app.swipeUp()
        app.swipeUp()

        let milestoneCollectionCell = app.collectionViews.cells.containing(.staticText, identifier: titleUUID).firstMatch
        XCTAssertTrue(milestoneCollectionCell.waitForExistence(timeout: 5))

        profilePage.tapEdit(profilePage.milestonesEditButton)

        deleteRow(milestoneCell)
    }

    /// Deletes a row in an edit screen. The list reloads after each delete, and a tap during the reload is lost.
    private func deleteRow(_ cell: XCUIElement) {
        XCTAssertTrue(cell.waitUntilSettled(timeout: 10), "the row is not on screen")
        cell.buttons.firstMatch.tap()
        let menu = app.otherElements.containing(.staticText, identifier: "Delete").firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 10), "the row's menu did not open")
        menu.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(cell.waitForNonExistence(timeout: 15), "the row was not deleted")
    }

    /// Deletes the rows a failed run left in an edit screen. The tests name every row they add with a UUID.
    private func removeLeftoverRows() {
        _ = app.tables.firstMatch.waitForExistence(timeout: 10)
        for _ in 0..<20 {
            let labels = app.tables.cells.staticTexts.allElementsBoundByIndex.map(\.label)
            guard let leftover = labels.first(where: { UUID(uuidString: $0) != nil }) else { return }
            deleteRow(app.tables.cells.containing(.staticText, identifier: leftover).firstMatch)
        }
    }
    
    func navigateToPublicProfile() {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password

        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)

        let leftMenu = LeftSideMenuPage(app: app, testCase: self)
        leftMenu.goToPublicProfile()
        // A swipe while the profile still slides in scrolls nothing.
        XCTAssertTrue(PublicProfilePage(app: app).aboutEditButton.waitUntilSettled(timeout: 15), "the profile did not open")
    }
}
