//
//  LoginViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.09.2024.

import Foundation
import SwiftUI

class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var loginStatus: LoginStatus?
    @Published var bannerErrorMessage: AuthBannerMessage = .none
    @Published var showErrorBanner: Bool = false
    
    var containerViewModel: AuthenticatorContainerViewModel
    
    init(containerViewModel: AuthenticatorContainerViewModel) {
        self.containerViewModel = containerViewModel
    }
    
    func areFieldsValid(emailField: String?, passwordField: String?) -> Bool {
        return (emailField?.isNotEmpty ?? false) && (emailField?.isValidEmail ?? false) && (passwordField?.count ?? 0 >= 8)
    }
    
    func attemptLogin() {
        self.loginStatus = nil
        if !areFieldsValid(emailField: username, passwordField: password) {
            loginStatus = LoginStatus.error(message: "The entered data is invalid")
            displayErrorBanner(bannerErrorMessage: .invalidData)
            return
        }
        
        containerViewModel.isLoading = true
        login(withUsername: username, password: password, then: {[weak self] newStatus in
            if newStatus == .mfaToken {
            self?.containerViewModel.password = self?.password ?? ""
            self?.containerViewModel.username = self?.username ?? ""
            }
            self?.loginStatus = newStatus
            self?.containerViewModel.isLoading = false
            switch newStatus {
            case .error(message: let message):
                self?.displayErrorBanner(bannerErrorMessage: .error)
            case .unknown:
                self?.displayErrorBanner(bannerErrorMessage: .invalidCredentials)
            default:
                break
            }
        })
    }
    
    func login(withUsername username: String?, password: String?, then handler: @escaping (LoginStatus) -> Void) {
        guard let email = username, let password = password, areFieldsValid(emailField: email, passwordField: password) else {
            handler(.error(message: .invalidFields))
            return
        }
        
        AuthenticationManager.shared.login(withUsername: email, password: password) { status in
            switch status {
            case .success, .mfaToken, .unknown:
                handler(status)
                
            case .error(message: _):
                handler(.error(message: .errorMessage))
            }
        }
    }
    
    func trackEvents() {
        EventsManager.setUserProfile(id: AuthenticationManager.shared.session?.account.accountID,
                                     email: AuthenticationManager.shared.session?.account.primaryEmail)
        EventsManager.trackEvent(event: .SignIn)
    }
    
    func displayErrorBanner(bannerErrorMessage: AuthBannerMessage) {
        if showErrorBanner {
            withAnimation {
                showErrorBanner = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.bannerErrorMessage = bannerErrorMessage
                withAnimation {
                    self.showErrorBanner = true
                }
            }
        } else {
            self.bannerErrorMessage = bannerErrorMessage
            withAnimation {
                showErrorBanner = true
            }
        }
    }
}
