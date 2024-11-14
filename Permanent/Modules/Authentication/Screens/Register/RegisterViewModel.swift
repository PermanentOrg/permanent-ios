//
//  RegisterViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.10.2024.

import SwiftUI

class RegisterViewModel: ObservableObject {
    @Published var fullname: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var registerStatus: RegisterStatus?
    @Published var agreeUpdates: Bool = false
    @Published var agreeTermsAndConditions: Bool = false
    
    var containerViewModel: AuthenticatorContainerViewModel
    
    init(containerViewModel: AuthenticatorContainerViewModel) {
        self.containerViewModel = containerViewModel
    }
    
    func areFieldsValid() -> Bool {
        return (fullname.isNotEmpty) && (email.isNotEmpty) && (email.isValidEmail) && (password.count >= 8)
    }
    
    func attemptRegister() {
        self.containerViewModel.isLoading = true
        signUp(then: { [weak self] newStatus in
            self?.containerViewModel.isLoading = false
            self?.registerStatus = newStatus
            switch newStatus {
            case .error(let message):
                self?.containerViewModel.displayErrorBanner(bannerErrorMessage: .error)
            case .unknown:
                self?.containerViewModel.displayErrorBanner(bannerErrorMessage: .invalidCredentials)
            default:
                break
            }
        })
    }
    
    func signUp(then handler: @escaping (RegisterStatus) -> Void) {
        let credentials: SignUpV2Credentials = (fullname, email, password, agreeUpdates)
        AuthenticationManager.shared.signUp(with: credentials) { status in
            switch status {
            case .success:
                handler(.success)
                
            case .error(message: _):
                handler(.error(message: .errorMessage))
            }
        }
    }

    func trackEvents() {
        EventsManager.setUserProfile(id: AuthenticationManager.shared.session?.account.accountID,
                                     email: AuthenticationManager.shared.session?.account.primaryEmail)
        EventsManager.trackEvent(event: .SignUp)
    }
}