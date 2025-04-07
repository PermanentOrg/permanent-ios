//
//  ChangePasswordViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.03.2025.
import SwiftUI

class ChangePasswordViewModel: ObservableObject {
    @Published var showBottomBanner: Bool = false
    @Published var bottomBannerMessage: BannerBottomMessage = .none
    @Published var showError: Bool = false
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    
    func verifyPasswordFields() {
        guard currentPassword.count > 7 else {
            showError = true
            bottomBannerMessage = .passwordTooShort
            displayBannerWithAutoClose()
            return
        }
        
        guard newPassword.count > 7 else {
            showError = true
            bottomBannerMessage = .passwordTooShort
            displayBannerWithAutoClose()
            return
        }
        
        guard newPassword == confirmPassword else {
            showError = true
            bottomBannerMessage = .passwordMismatch
            displayBannerWithAutoClose()
            return
        }
        
        changePassword()
    }
    
    func changePassword() {
        
    }
    
    func displayBanner() {
        if showBottomBanner {
            withAnimation {
                showBottomBanner = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation {
                    self.showBottomBanner = true
                }
            }
        } else {
            withAnimation {
                showBottomBanner = true
            }
        }
    }
    
    func displayBannerWithAutoClose() {
        displayBanner()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            withAnimation {
                self?.showBottomBanner = false
            }
        }
    }
    
    func evaluatePasswordStrength(_ password: String) -> PasswordStrength {
        if password.isEmpty {
            return .weak
        }
        
        let strengthLevels: [(regex: String, strength: PasswordStrength)] = [
            ("^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[!@#$%^&*()_+\"|{}:;<>,.?/~`]).{10,}$", .strong),
            ("^(?=.*[a-zA-Z])(?=.*\\d)(?=.*[!@#$%^&*()_+\"|{}:;<>,.?/~`]).{8,}$", .medium),
            ("^(?=.*[a-zA-Z])(?=.*\\d).{6,}$", .weak)
        ]
        
        for (regex, strength) in strengthLevels {
            if NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: password) {
                return strength
            }
        }
        return .weak
    }
}

enum PasswordStrength: String {
    case weak = "weak"
    case medium = "medium"
    case strong = "strong"
    
    var color: Color {
        switch self {
        case .weak:
            return Color(red: 0.94, green: 0.27, blue: 0.22)
        case .medium:
            return Color(red: 0.97, green: 0.56, blue: 0.03)
        case .strong:
            return Color(red: 0.07, green: 0.72, blue: 0.42)
        }
    }
}

