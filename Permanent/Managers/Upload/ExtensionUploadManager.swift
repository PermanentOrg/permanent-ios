//
//  ExtensionUploadManager.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.06.2022.
//

import Foundation

class ExtensionUploadManager {
    static let appSuiteGroup = "group.permanent.org.share"
    static let savedFilesKey = "group.permanent.org.share.files"
    
    static let shared = ExtensionUploadManager()
    
    func save(files: [FileInfo]) throws {
        NSKeyedArchiver.setClassName("Permanent.FileInfo", for: FileInfo.self)
        NSKeyedArchiver.setClassName("Permanent.FolderInfo", for: FolderInfo.self)
        
        let prefsManager = PreferencesManager(withGroupName: Self.appSuiteGroup)
        let nsFiles = NSArray(array: files)
        
        try prefsManager.setNonPlistObject(nsFiles, forKey: Self.savedFilesKey)
    }
    
    func savedFiles() throws -> [FileInfo] {
        NSKeyedUnarchiver.setClass(FileInfo.self, forClassName: "Permanent.FileInfo")
        NSKeyedUnarchiver.setClass(FolderInfo.self, forClassName: "Permanent.FolderInfo")
        
        var files: [FileInfo] = []
        
        let prefsManager = PreferencesManager(withGroupName: Self.appSuiteGroup)
        if let nsFiles: NSArray = try prefsManager.getNonPlistObject(forKey: Self.savedFilesKey) {
            files = (nsFiles as? [FileInfo]) ?? []
        }
        
        return files
    }
    
    func clearSavedFiles() {
        let prefsManager = PreferencesManager(withGroupName: Self.appSuiteGroup)
        prefsManager.removeValue(forKey: Self.savedFilesKey)
    }
}
