//
//  ShareAccessLevel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.09.2025.
//

import Foundation
import SwiftUI

enum ShareAccessLevel: CaseIterable {
    case anyoneCanView
    case restricted
    
    var title: String {
        switch self {
        case .anyoneCanView: return "Anyone can view"
        case .restricted: return "Restricted"
        }
    }
    
    var description: String {
        switch self {
        case .anyoneCanView: return "Anyone with the link can view and download."
        case .restricted: return "The user must have an account and be logged in to view."
        }
    }
    
    var icon: Image {
        switch self {
        case .anyoneCanView: return Image(.publishGlobe)
        case .restricted: return Image(systemName: "lock.fill")
        }
    }
    
    var iconColor: Color {
        switch self {
        case .anyoneCanView: return .green
        case .restricted: return .gray
        }
    }
}
