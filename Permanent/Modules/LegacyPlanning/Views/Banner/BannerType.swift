//
//  BannerType.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 30.05.2023.

import Foundation
import UIKit
import KeychainSwift

enum BannerType: String {
    case legacy = "org.permanent.banner.legacy"
    case noBanner
}

extension BannerType {
    
    var title: String? {
        switch self {
        case .legacy:
            return "Legacy Planning"
        default:
            return ""
        }
    }
    
    var subtitle: String? {
        switch self {
        case .legacy:
            return "Your Legacy Plan will determine when, how, and with whom your materials will be shared when you are gone."
        default:
            return ""
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .legacy:
            return UIImage(named: "legacyPlanning")
        default:
            return UIImage(named: "")
        }
    }
}

extension BannerType {
    
    func getKey() -> String? {
        guard let accountId: Int = PermSession.currentSession?.account.accountID else {
            return nil
        }
        return "\(self.rawValue).\(accountId)"
    }
    
    mutating func shouldShowBanner() -> Bool {
        guard let key = getKey() else {
            return false
        }
        if self == .noBanner {
            return false
        }
        guard let show = KeychainSwift().getBool(key) else {
            return true
        }
        return show
    }
    
    mutating func didShowBanner() {
        guard let key = getKey() else {
            return
        }
        KeychainSwift().set(false, forKey: key)
    }
}
