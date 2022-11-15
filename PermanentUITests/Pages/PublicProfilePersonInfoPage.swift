//
//  PublicProfilePersonInfoPAge.swift
//  PermanentUITests
//
//  Created by Vlad Alexandru Rusu on 15.11.2022.
//

import Foundation
import XCTest

class PublicProfilePersonInfoPage {
    let app: XCUIApplication
    
    var fullNameTextField: XCUIElement { app.textFields["Full Name"].firstMatch }
    var nicknameTextField: XCUIElement { app.textFields["Nickname"].firstMatch }
    var genderTextField: XCUIElement { app.textFields["Gender"].firstMatch }
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    func fillFullName() -> String {
        let fullNameUUID = UUID().uuidString
        fullNameTextField.selectAndDeleteText(inApp: app)
        fullNameTextField.typeText(fullNameUUID)
        
        return fullNameUUID
    }
    
    func fillNickname() -> String {
        let nicknameUUID = UUID().uuidString
        nicknameTextField.selectAndDeleteText(inApp: app)
        nicknameTextField.typeText(nicknameUUID)
        
        return nicknameUUID
    }
    
    func fillGender() -> String {
        let genderUUID = UUID().uuidString
        genderTextField.selectAndDeleteText(inApp: app)
        genderTextField.typeText(genderUUID)
        
        return genderUUID
    }
}
