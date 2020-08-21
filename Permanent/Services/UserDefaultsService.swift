//
//  UserDefaultsService.swift
//  Permanent
//
//  Created by Lucian Cerbu on 20/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import Foundation

// MARK: - Getting information about onboarding screen first time run
class UserDefaultsService {
    static let shared = UserDefaultsService()
    func isNewUser() -> Bool {
        return !UserDefaults.standard.bool(forKey: "isNewUser")
    }
    func setIsNotNewUser() {
        UserDefaults.standard.set(true, forKey: "isNewUser")
    }
}

