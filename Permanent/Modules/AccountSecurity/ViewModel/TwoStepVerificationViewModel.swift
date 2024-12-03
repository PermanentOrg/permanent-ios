//
//  TwoStepVerificationViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.11.2024.

import Foundation
import SwiftUI

class TwoStepVerificationViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isTwoFactorEnabled: Bool
    @Published var twoFactorMethods: [TwoFactorMethod]
    
    /// Initializes the view model with the current 2FA state
    /// - Parameters:
    ///   - isTwoFactorEnabled: Boolean indicating if 2FA is currently enabled
    ///   - twoFactorMethods: Array of configured 2FA methods
    /// Methods are sorted to prioritize SMS as the default method
    init(isTwoFactorEnabled: Bool, twoFactorMethods: [TwoFactorMethod]) {
        self.isTwoFactorEnabled = isTwoFactorEnabled
        self.twoFactorMethods = twoFactorMethods.sorted { method1, method2 in
            if method1.type == .sms {
                return true
            } else if method2.type == .sms {
                return false
            }
            return false
        }
    }
} 
