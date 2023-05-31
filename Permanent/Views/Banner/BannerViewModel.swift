//
//  BannerViewModel.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 30.05.2023.

import Foundation
import KeychainSwift

struct BannerViewModel {
    
    private  let keychain = KeychainSwift()
    
    private lazy var key: String? = {
        guard let accountId: Int = PermSession.currentSession?.account.accountID else {
            return nil
        }
        return "\(type.rawValue).\(accountId)"
    }()
    
    var type: BannerType
    
    init(type: BannerType) {
        self.type = type
    }
    
    mutating func shouldShowBanner() -> Bool {
        guard let key = key else {
            return false
        }
        guard let show = keychain.getBool(key) else {
            return true
        }
        return show
    }
    
    mutating func dismiss() {
        guard let key = key else {
            return
        }
        keychain.set(false, forKey: key)
    }
}
