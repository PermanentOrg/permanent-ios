//
//  InviteCodeManager.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.07.2025.
//

import Foundation

class InviteCodeManager {
    static let shared = InviteCodeManager()
    
    private init() {}
    
    /// Store an invite code to be used later during signup
    func storeInviteCode(_ inviteCode: String) {
        PreferencesManager.shared.set(inviteCode, forKey: Constants.Keys.StorageKeys.pendingInviteCode)
    }
    
    /// Retrieve and consume the stored invite code (removes it after retrieving)
    func getAndConsumeInviteCode() -> String? {
        let inviteCode: String? = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.pendingInviteCode)
        
        if inviteCode != nil {
            // Remove the code after retrieving it
            PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.pendingInviteCode)
        }
        
        return inviteCode
    }
    
    /// Check if there's a pending invite code without consuming it
    func hasPendingInviteCode() -> Bool {
        let inviteCode: String? = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.pendingInviteCode)
        return inviteCode != nil && !inviteCode!.isEmpty
    }
    
    /// Clear any stored invite code
    func clearInviteCode() {
        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.pendingInviteCode)
    }
}
