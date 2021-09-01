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
    
    func getNonPlistObject<T: NSCoding>(forKey key: String) throws -> T? {
        guard let data = userDefaults.value(forKey: key) as? Data else { return nil }
        return try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? T
    }
    
    func getCodableObject<T: Codable>(forKey key: String) throws -> T? {
        guard let data = userDefaults.value(forKey: key) as? Data else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func set<T>(_ value: T, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    func setNonPlistObject<T: NSCoding>(_ value: T, forKey key: String) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false)
        userDefaults.setValue(data, forKey: key)
    }
    
    func setCodableObject<T: Codable>(_ value: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(value)
        userDefaults.setValue(data, forKey: key)
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
        guard let object = userDefaults.data(forKey: key) else {
            return nil
        }
        
        let decodedData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(object) as? T
        return decodedData
    }
    
}
