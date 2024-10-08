//
//  ForgotPasswordViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.10.2024.

import Foundation
import SwiftUI

class ForgotPasswordViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var requestStatus: RequestStatus?
    
    var containerViewModel: AuthenticatorContainerViewModel
    let authRepo: AuthRepository
    
    init(containerViewModel: AuthenticatorContainerViewModel) {
        self.containerViewModel = containerViewModel
        self.authRepo = AuthRepository()
    }
    
    
    func areFieldsValid(emailField: String?) -> Bool {
        return (emailField?.isNotEmpty ?? false) && (emailField?.isValidEmail ?? false)
    }
    
    func makeForgotPasswordRequest() {
        guard areFieldsValid(emailField: email) else {
            containerViewModel.displayErrorBanner(bannerErrorMessage: .invalidData)
            return
        }
        
        containerViewModel.isLoading = true
        AuthenticationManager.shared.forgotPassword(withEmail: email) { status in
            self.containerViewModel.isLoading = false
            self.containerViewModel.setContentType(.forgotPasswordConfirmation)
        }
    }
}
