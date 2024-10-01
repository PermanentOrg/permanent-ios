//
//  AuthVerifyIdentityViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.09.2024.
import SwiftUI

class AuthVerifyIdentityViewModel: ObservableObject {
    var containerViewModel: AuthenticatorContainerViewModel
    let authRepo: AuthRepository
    @Published var pinCode: String = ""
    
    init(containerViewModel: AuthenticatorContainerViewModel) {
        self.containerViewModel = containerViewModel
        self.pinCode = ""
        self.authRepo = AuthRepository()
    }
    
    func verify2FA(then handler: @escaping AuthLoginResponse) {
        guard pinCode.count == 4 else {
            containerViewModel.displayErrorBanner(bannerErrorMessage: .emptyPinCode)
            handler(.emptyPinCode)
            return
        }
        containerViewModel.isLoading = true
        AuthenticationManager.shared.verify2FA(code: pinCode) { result in
            self.containerViewModel.isLoading = false
            switch result {
            case .success:
                handler(.success)
                EventsManager.trackEvent(event: .SignIn)

            case .error(let message):
                self.containerViewModel.displayErrorBanner(bannerErrorMessage: .invalidPinCode)
                handler(.invalidPinCode)
            }
        }
    }
    
    func resendPinCode() {
        containerViewModel.isLoading = true
        AuthenticationManager.shared.login(withUsername: containerViewModel.username, password: containerViewModel.password) { status in
            self.containerViewModel.isLoading = false
            switch status {
            case .error(message: _):
                self.containerViewModel.displayErrorBanner(bannerErrorMessage: .resentCodeError)
            default:
                self.containerViewModel.displayErrorBanner(bannerErrorMessage: .successResendCode)
                return
            }
        }
    }
}
