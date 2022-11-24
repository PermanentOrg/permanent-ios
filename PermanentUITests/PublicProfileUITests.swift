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
        profilePage.aboutEditButton.tap()
        
        let aboutPage = PublicProfileAboutPage(app: app)
        let shortUUID = aboutPage.addShortDescription()
        let longUUID = aboutPage.addLongDescription()
        
        aboutPage.doneButton.tap()
        
        app.collectionViews.otherElements.staticTexts["Show More"].tap()
        
        let shortDescriptionCell = app.collectionViews.cells.containing(.staticText, identifier: shortUUID).firstMatch
        XCTAssertTrue(shortDescriptionCell.waitForExistence(timeout: 5))
        
        let longDescriptionCell = app.collectionViews.cells.containing(.staticText, identifier: longUUID).firstMatch
        XCTAssertTrue(longDescriptionCell.waitForExistence(timeout: 5))
    }
    
    func testPersonInformation() {
        navigateToPublicProfile()
        
        let profilePage = PublicProfilePage(app: app)
        profilePage.personInformationEditButton.tap()
        
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
    }
    
    func testOnlinePresence() {
        navigateToPublicProfile()
        
        app.swipeUp()
        
        let personInformationHeader = app.collectionViews.otherElements.containing(.staticText, identifier: "Online Presence").firstMatch
        personInformationHeader.staticTexts["Edit"].tap()
        
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
        
        let emailCollectionCell = app.collectionViews.cells.containing(.staticText, identifier: emailUUID).firstMatch
        XCTAssertTrue(emailCollectionCell.waitForExistence(timeout: 5))
        
        let linkCollectionCell = app.collectionViews.cells.containing(.staticText, identifier: linkUUID).firstMatch
        XCTAssertTrue(linkCollectionCell.waitForExistence(timeout: 5))
        
        personInformationHeader.staticTexts["Edit"].tap()
        
        emailCell.buttons.firstMatch.tap()
        app.otherElements.containing(.staticText, identifier: "Delete").firstMatch.buttons.element(boundBy: 1).tap()
        
        app.waitForActivityIndicators()
        
        linkCell.buttons.firstMatch.tap()
        app.otherElements.containing(.staticText, identifier: "Delete").firstMatch.buttons.element(boundBy: 1).tap()
        sleep(1)
    }
    
    func testMilestones() {
        navigateToPublicProfile()
        
        app.swipeUp()
        
        let milestonesHeader = app.collectionViews.otherElements.containing(.staticText, identifier: "Milestones").firstMatch
        milestonesHeader.staticTexts["Edit"].tap()
        
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
        
        let milestoneCollectionCell = app.collectionViews.cells.containing(.staticText, identifier: titleUUID).firstMatch
        XCTAssertTrue(milestoneCollectionCell.waitForExistence(timeout: 5))
        
        milestonesHeader.staticTexts["Edit"].tap()
        
        milestoneCell.buttons.firstMatch.tap()
        app.otherElements.containing(.staticText, identifier: "Delete").firstMatch.buttons.element(boundBy: 1).tap()
        sleep(1)
    }
    
    func navigateToPublicProfile() {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password
        
        let signUpPage = SignUpPage(app: app, testCase: self)
        signUpPage.navigateToLogin()
        
        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)
        
        let leftMenu = LeftSideMenuPage(app: app, testCase: self)
        leftMenu.goToPublicProfile()
    }
}
