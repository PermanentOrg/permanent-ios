//
//  SessionKeychainHandler.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 22.07.2022.
//

import Foundation
import KeychainSwift

class SessionKeychainHandler {
    static let keychainAuthDataKey = "org.permanent.authData"
    
    func savedSession() throws -> PermSession? {
        let authData = KeychainSwift().getData(Self.keychainAuthDataKey)
        if let authData = authData {
            let session = try JSONDecoder().decode(PermSession.self, from: authData)
            return session
        } else {
            return nil
        }
    }
    
    func saveSession(_ session: PermSession) throws {
        let authData = try JSONEncoder().encode(session)
        KeychainSwift().set(authData, forKey: Self.keychainAuthDataKey)
    }
    
    func clearSession() {
        KeychainSwift().delete(Self.keychainAuthDataKey)
    }
}
