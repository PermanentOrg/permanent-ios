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
    @Published var bannerErrorMessage: AuthBannerMessage = .none
    @Published var showErrorBanner: Bool = false
    
    init(containerViewModel: AuthenticatorContainerViewModel) {
        self.containerViewModel = containerViewModel
        self.pinCode = ""
        self.authRepo = AuthRepository()
    }
    
    func verify2FA(then handler: @escaping AuthLoginResponse) {
        guard pinCode.count == 4 else {
            displayErrorBanner(bannerErrorMessage: .emptyPinCode)
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
                self.displayErrorBanner(bannerErrorMessage: .invalidPinCode)
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
                self.displayErrorBanner(bannerErrorMessage: .resentCodeError)
            default:
                self.displayErrorBanner(bannerErrorMessage: .successResendCode)
                return
            }
        }
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

enum FocusPin: Hashable {
    case pin(Int)
}
