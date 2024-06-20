//
//  OnboardingPendingArchives.swift
//  Permanent
//
//  Created by Lucian Cerbu on 20.06.2024.

import Foundation

struct OnboardingPendingArchives: Identifiable, Decodable {
    var id = UUID()
    
    var fullname: String
    var accessType: String
}
