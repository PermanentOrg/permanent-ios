//
//  FileHelper.swift
//  Permanent
//
//  Created by Adrian Creteanu on 10/11/2020.
//

import Foundation

class FileHelper {
    var defaultDirectoryURL: URL?
    
    init() {
        do {
            self.defaultDirectoryURL = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
        } catch {
            print("Error. Could not get documents directory URL.", error)
        }
    }
    
    func saveFile(_ data: Data, named name: String, withExtension extension: String) -> URL? {
        do {
            let fileURL = self.defaultDirectoryURL!
                .appendingPathComponent(name)
                .appendingPathExtension(`extension`)
            
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error. Could not save file.", error)
            return nil
        }
    }
    
    func saveFile(at url: URL, named name: String? = nil) -> URL? {
        do {
            let fileURL = self.defaultDirectoryURL!
                .appendingPathComponent(name ?? UUID().uuidString)
          
            // If we already have an item stored at this path, we remove it first.
            try? FileManager.default.removeItem(at: fileURL)
            
            try FileManager.default.copyItem(at: url, to: fileURL)
            return fileURL
            
        } catch {
            print("Error. Could not save file.", error)
            return nil
        }
    }
    
    func deleteFile(at location: URL) {
        DispatchQueue.global(qos: .utility).async {
            try? FileManager.default.removeItem(at: location)
        }
    }
    
    func hasFile(named name: String) -> Bool {
        let fileURL = self.defaultDirectoryURL!.appendingPathComponent(name)
        let filePath = fileURL.path
        
        return FileManager.default.fileExists(atPath: filePath)
    }
    
    func url(forFileNamed name: String) -> URL? {
        if hasFile(named: name) {
            return self.defaultDirectoryURL!.appendingPathComponent(name)
        }
        
        return nil
    }
}
