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
        
        let nsFiles = NSArray(array: files)
        
        try PreferencesManager().setNonPlistObject(nsFiles, forKey: Self.savedFilesKey)
    }
    
    func savedFiles() throws -> [FileInfo] {
        NSKeyedUnarchiver.setClass(FileInfo.self, forClassName: "Permanent.FileInfo")
        NSKeyedUnarchiver.setClass(FolderInfo.self, forClassName: "Permanent.FolderInfo")
        
        var files: [FileInfo] = []
        
        if let nsFiles: NSArray = try PreferencesManager().getNonPlistObject(forKey: Self.savedFilesKey) {
            files = (nsFiles as? [FileInfo]) ?? []
        }
        
        return files
    }
    
    func clearSavedFiles() {
        PreferencesManager().removeValue(forKey: Self.savedFilesKey)
    }
}
