//
//  OnboardingStorageValues.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.04.2024.

import Foundation
import SwiftUI

class OnboardingStorageValues: ObservableObject {
    @Published var archiveType: ArchiveType = .person
    @Published var textFieldText: String = ""
    @Published var selectedPath: [OnboardingPath] = []
    @Published var fullName: String = AuthenticationManager.shared.session?.account.fullName ?? ""
    
    let welcomeMessage: String = "We’re so glad you’re here!\n\nAt Permanent, it is our mission to provide a safe and secure place to store, preserve, and share the digital legacy of all people, whether that's for you or for your friends, family, interests or organizations.\n\nWe know that starting this journey can sometimes be overwhelming, but don’t worry. We’re here to help you every step of the way."

    func getIndefiniteArticle() -> String {
        if archiveType == .individual || archiveType == .organization {
            return "an"
        }
        return "a"
    }
    
    func togglePath(path: OnboardingPath) {
        if let index = selectedPath.firstIndex(of: path)
        {
            selectedPath.remove(at: index)
        } else {
            selectedPath.append(path)
        }
    }
}
