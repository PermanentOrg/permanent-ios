//
//  UserDefaultManager.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 14.10.2024.

import Foundation

struct UserDefaultManager {
    
    func saveFile(fileInfo: FileInfo) {
        var array = UserDefaults.standard.array(forKey: "savedFiles")
        if array == nil {
            array = []
        }
        array?.append(fileInfo.assetID)
        UserDefaults.standard.set(array, forKey: "savedFiles")
    }
    
    func getFiles() -> [String] {
        return UserDefaults.standard.array(forKey: "savedFiles") as? [String] ?? []
    }
}
