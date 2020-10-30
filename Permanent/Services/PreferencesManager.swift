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
    
    func removeValue(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    func removeValues(forKeys keys: [String]) {
        keys.forEach { removeValue(forKey: $0) }
    }
    
    func setCustomObject<T>(_ value: T, forKey key: String) throws {
        let encodedData = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false)
        set(encodedData, forKey: key)
    }
    
    func getCustomObject<T>(forKey key: String) throws -> T? {
        guard let object: Data = getValue(forKey: key) else { return nil }
        
        let decodedData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(object)
        
        return decodedData as? T
    }
    
}
