//
//  PreferencesManager.swift
//  Permanent
//
//  Created by Adrian Creteanu on 28/09/2020.
//

import Foundation

class PreferencesManager {
    static var shared = PreferencesManager()

    fileprivate var userDefaults = UserDefaults.standard

    func getValue<T>(forKey key: String) -> T? {
        return userDefaults.value(forKey: key) as? T
    }

    func set<T>(_ value: T, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
}
