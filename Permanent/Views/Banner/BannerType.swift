//
//  BannerType.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 30.05.2023.

import Foundation
import UIKit

enum BannerType: String {
    case legacy = "org.permanent.banner.legacy"
}

extension BannerType {
    
    var title: String {
        switch self {
        case .legacy:
            return "Legacy Planning"
        }
    }
    
    var subtitle: String {
        switch self {
        case .legacy:
            return "Your Legacy Plan will determine when, how, and with whom your materials will be shared."
        }
    }
    
    var icon: UIImage {
        switch self {
        case .legacy:
            return UIImage()
        }
    }
}
