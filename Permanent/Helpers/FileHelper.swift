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
    
    // create protocol for these
    func saveFile(_ data: Data, withExtension extension: String) -> URL? {
        do {
            let fileURL = self.defaultDirectoryURL!
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(`extension`)
            
            try data.write(to: fileURL)
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
}
