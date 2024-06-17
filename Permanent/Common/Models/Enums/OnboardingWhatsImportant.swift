//
//  OnboardingWhatsImportant.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.05.2024.

import Foundation

enum OnboardingWhatsImportant: String, CaseIterable, Identifiable {
    var id: String { return self.rawValue }
    
    case access, supporting, preserving, professional, collaborate, interest = ""
    
    var description: String {
        switch self {
        case .access:
            return "Access to a safe and secure digital storage platform"
        case .supporting:
            return "Supporting a mission-driven nonprofit"
        case .preserving:
            return "Preserving family history or genealogy research"
        case .professional:
            return "Professional business needs/clients"
        case .collaborate:
            return "Collaborate with a family member, friend, or colleague"
        case .interest:
            return "Interest in digital preservation solutions"
        }
    }
    
    var tag: String {
        switch self {
        case .access:
            return "safe"
        case .supporting:
            return "nonprofit"
        case .preserving:
            return "genealogy"
        case .professional:
            return "professional"
        case .collaborate:
            return "collaborate"
        case .interest:
            return "digipres"
        }
    }
}
