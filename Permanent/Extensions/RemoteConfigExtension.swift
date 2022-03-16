//
//  RemoteConfigExtension.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.03.2022.
//

import Foundation
import Firebase

/// Enum of API Errors
enum RemoteControlError: Error {
    /// No data received from the server.
    case fetchError
    /// The server response was invalid
    case invalidResponse
    
    var message: String {
        switch self {
        case .fetchError: return "There was a fetch error.".localized()
        case .invalidResponse: return .errorMessage
        }
    }
}

typealias RemoteConfigResponse = (_ appMinVersion: String?, _ errorMessage: RemoteControlError?) -> Void
extension RemoteConfig {
    static func fetchCloudValues(completion: @escaping RemoteConfigResponse) {
        let remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        remoteConfig.configSettings = settings
        let fetchDuration: TimeInterval = 0
        RemoteConfig.remoteConfig().fetch(withExpirationDuration: fetchDuration) { status, error in
            if let error = error {
                print("Got an error fetching remote values \(error)")
                completion(nil, RemoteControlError.fetchError)
                return
            }
            
            RemoteConfig.remoteConfig().activate { result, error in
                if result {
                    guard let minAppVersion = RemoteConfig.remoteConfig().configValue(forKey: "min_app_version_ios").stringValue else {
                        completion(nil, RemoteControlError.invalidResponse)
                        return
                    }
                    
                    if minAppVersion.isNotEmpty {
                        print("Our app's min version is \(minAppVersion)")
                        completion(minAppVersion, nil)
                        return
                    } else {
                        completion(nil, RemoteControlError.invalidResponse)
                        return
                    }
                }
            }
        }
    }
    
    static func isAppUpdated(completion: @escaping (Bool?) -> ()) {
        var pass = true
        fetchCloudValues { result, error in
            guard let result = result else {
                completion(nil)
                return
            }
            let deviceVersionArray = Bundle.release.components(separatedBy: ".")
            let currentVersionArray = result.components(separatedBy: ".")
            
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
            
            print("Min app Version \(result)")
            print("Release / build Version: \(Bundle.release) (\(Bundle.build))")
            
            completion(pass)
            return
        }
    }
}
