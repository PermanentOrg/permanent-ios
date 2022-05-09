//
//  RCValues.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.03.2022.
//

import Firebase
import Foundation

class RCValues {
    static let sharedInstance = RCValues()
    static var appNeedUpdate = false
    
    enum ValueKey: String {
        case appMinValue
        
        var name: String {
            switch self {
            case .appMinValue:
                return "min_app_version_ios"
            }
        }
    }
    
    private init() {
        loadDefaultValues()
    }
    
    func loadDefaultValues() {
        let appDefaults: [String: Any?] = [
            ValueKey.appMinValue.name: "1.0.0"
        ]
        RemoteConfig.remoteConfig().setDefaults(appDefaults as? [String: NSObject])
    }
    
    static func activateDebugMode() {
        let settings = RemoteConfigSettings()
        /// WARNING: Don't actually do this in production!
        settings.minimumFetchInterval = 0
        RemoteConfig.remoteConfig().configSettings = settings
    }
    
    static func fetchCloudValues(completion: @escaping (Bool) -> Void) {
        if APIEnvironment.defaultEnv == .staging {
            activateDebugMode()
        }
        
        RemoteConfig.remoteConfig().fetch { _, error in
            if let _ = error {
                completion(false)
                return
            }
            
            RemoteConfig.remoteConfig().activate { _, _ in
                completion(true)
            }
        }
    }
    
    func version(forKey key: ValueKey) -> [String] {
        let value = RemoteConfig.remoteConfig()[key.name]
            .stringValue ?? "0.0.0"
        let convertedValue = value.components(separatedBy: ".")
        return convertedValue
    }
    
    static func getPublicArchives() -> [PopularArchive] {
        var archives: [PopularArchive] = []
        var popularArchives: [PopularArchive]
        let json = RemoteConfig.remoteConfig()["popular_public_galleries"].jsonValue ?? []
        
        if let value = json as? [String: [[String : Any]]],
           let valueArchives = value["archives"]
        {
            for item in valueArchives {
                if let name = item["name"] as? String,
                   let archiveID = item["archiveID"] as? Int,
                   let archiveNbr = item["archiveNbr"] as? String {
                    archives.append(PopularArchive(name: name, archiveID: archiveID, archiveNbr: archiveNbr))
                }
            }
        }
        return archives
    }
    
    static func verifyAppVersion() {
        let currentVersionArray = RCValues.sharedInstance.version(forKey: .appMinValue)
        let deviceVersionArray = Bundle.release.components(separatedBy: ".")

        if currentVersionArray == ["0", "0", "0"] {
            return
        }
        
        var pass = true
        var pos = 0
        while currentVersionArray.count > pos || deviceVersionArray.count > pos {
            let currentVersion = currentVersionArray.count > pos ? Int(currentVersionArray[pos]) : 0
            let deviceVersion = deviceVersionArray.count > pos ? Int(deviceVersionArray[pos]) : 0
            
            if currentVersion ?? 0 > deviceVersion ?? 0 {
                pass = false
                break
            } else if currentVersion ?? 0 < deviceVersion ?? 0 {
                pass = true
                break
            }
            pos += 1
        }
        appNeedUpdate = !pass
    }
}
