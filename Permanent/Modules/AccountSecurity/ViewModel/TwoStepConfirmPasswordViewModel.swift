//
//  TwoStepConfirmPasswordViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 19.12.2024.

import SwiftUI

class TwoStepConfirmPasswordViewModel: ObservableObject {
    @Published var textFieldPassword: String = ""
    @Published var isLoading: Bool = false
    let authRepo: AuthRepository = AuthRepository()
    
    var containerViewModel: TwoStepConfirmationContainerViewModel
    
    init(containerViewModel: TwoStepConfirmationContainerViewModel) {
        self.containerViewModel = containerViewModel
    }
    
    func attemptLogin() {
        containerViewModel.showErrorBanner = false
        if !areFieldsValid(emailField: AuthenticationManager.shared.session?.account.primaryEmail, passwordField: textFieldPassword) {
            containerViewModel.displayErrorBanner(bannerErrorMessage: .invalidCredentials)
            return
        }
        
        isLoading = true
        simpleLoginReq(then: {[weak self] newStatus in
            self?.isLoading = false
            switch newStatus {
            case .success:
                self?.containerViewModel.setContentType(.chooseVerification)
            case .error(message: _):
                self?.containerViewModel.displayErrorBanner(bannerErrorMessage: .error)
            case .unknown:
                self?.containerViewModel.displayErrorBanner(bannerErrorMessage: .invalidCredentials)
            default:
                break
            }
        })
    }
    
    func simpleLoginReq(then handler: @escaping (LoginStatus) -> Void) {
        authRepo.login(withUsername: AuthenticationManager.shared.session?.account.primaryEmail ?? "", password: textFieldPassword) { result in
            switch result {
            case .success(let loginResponse):
                if loginResponse.isSuccessful == true {
                    handler(.success)
                } else if let message = loginResponse.results?.first?.message?.first,
                          let loginError = LoginError(rawValue: message) {
                    if loginError == .mfaToken {
                        handler(.success)
                    } else if loginError == .unknown {
                        handler(.unknown)
                    } else {
                        handler(.error(message: loginError.description))
                    }
                } else {
                    handler(.error(message: .errorMessage))
                }
                
            case .failure( _):
                handler(.error(message: "Authorization error".localized()))
            }
        }
    }
    
    func areFieldsValid(emailField: String?, passwordField: String?) -> Bool {
        return (emailField?.isNotEmpty ?? false) && (emailField?.isValidEmail ?? false) && (passwordField?.count ?? 0 >= 8)
    }
    
    func login(withUsername username: String?, password: String?, then handler: @escaping (LoginStatus) -> Void) {
        guard let email = username, let password = password, areFieldsValid(emailField: email, passwordField: password) else {
            handler(.error(message: .invalidFields))
            return
        }
        
        AuthenticationManager.shared.login(withUsername: email, password: password) { status in
            switch status {
            case .success, .mfaToken, .unknown:
                PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.twoFactorAuthEnabled)
                handler(status)
                
            case .error(message: _):
                handler(.error(message: .errorMessage))
            }
        }
    }
    
    
}
