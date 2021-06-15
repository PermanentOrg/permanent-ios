//
//  FileHelper.swift
//  Permanent
//
//  Created by Adrian Creteanu on 10/11/2020.
//

import Foundation

class FileHelper {
    var defaultDirectoryURL: URL?
    var uploadDirectoryURL: URL?
    
    init() {
        do {
            self.defaultDirectoryURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            
            let libraryURL = try FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            try FileManager.default.createDirectory(at: libraryURL.appendingPathComponent("uploads"), withIntermediateDirectories: true, attributes: nil)
            uploadDirectoryURL = libraryURL.appendingPathComponent("uploads")
            
        } catch {
            print("Error. Could not get documents directory URL.", error)
        }
    }
    
    @discardableResult
    func saveFile(_ data: Data, named name: String, withExtension extension: String, isDownload: Bool = true) -> URL? {
        do {
            var fileURL: URL
            if isDownload {
               fileURL = self.defaultDirectoryURL!
            } else {
                fileURL = self.uploadDirectoryURL!
            }
            fileURL = fileURL.appendingPathComponent(name).appendingPathExtension(`extension`)
            
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
    
    func hasFile(named name: String, isDownload: Bool = true) -> Bool {
        var fileURL: URL
        if isDownload {
           fileURL = self.defaultDirectoryURL!
        } else {
            fileURL = self.uploadDirectoryURL!
        }
        fileURL = fileURL.appendingPathComponent(name)
        let filePath = fileURL.path
        
        return FileManager.default.fileExists(atPath: filePath)
    }
    
    func url(forFileNamed name: String, isDownload: Bool = true) -> URL? {
        if hasFile(named: name, isDownload: isDownload) {
            var fileURL: URL
            if isDownload {
               fileURL = self.defaultDirectoryURL!
            } else {
                fileURL = self.uploadDirectoryURL!
            }
            fileURL = fileURL.appendingPathComponent(name)
            return fileURL
        }
        
        return nil
    }
    
    func data(forFileNamed name: String, isDownload: Bool) -> Data? {
        guard let url = url(forFileNamed: name, isDownload: isDownload) else { return nil }
        
        return try? Data(contentsOf: url)
    }
}
