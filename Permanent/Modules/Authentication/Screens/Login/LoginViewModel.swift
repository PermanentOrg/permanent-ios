//
//  LoginViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.09.2024.

import Foundation
import SwiftUI

class LoginViewModel: ObservableObject, LoginEventProtocol {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var loginStatus: LoginStatus?
    @Published var isOfflineBannerDisplayed: Bool = false
    
    var containerViewModel: AuthenticatorContainerViewModel
    
    init(containerViewModel: AuthenticatorContainerViewModel) {
        self.containerViewModel = containerViewModel
        
        if isBeforeDeadline() && containerViewModel.maintenanceTopBannerWasDisplayed == false {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: { [weak self] in
                    withAnimation {
                        self?.isOfflineBannerDisplayed = true
                    }
            })
        }
    }
    
    func areFieldsValid(emailField: String?, passwordField: String?) -> Bool {
        return (emailField?.isNotEmpty ?? false) && (emailField?.isValidEmail ?? false) && (passwordField?.count ?? 0 >= 8)
    }
    
    func attemptLogin() {
        self.loginStatus = nil
        if !areFieldsValid(emailField: username, passwordField: password) {
            loginStatus = LoginStatus.error(message: "The entered data is invalid")
            containerViewModel.displayErrorBanner(bannerErrorMessage: .invalidData)
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
                self?.containerViewModel.displayErrorBanner(bannerErrorMessage: .error)
            case .unknown:
                self?.containerViewModel.displayErrorBanner(bannerErrorMessage: .invalidCredentials)
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
                PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.twoFactorAuthEnabled)
                handler(status)
                
            case .error(message: _):
                handler(.error(message: .errorMessage))
            }
        }
    }
    
    private func isBeforeDeadline() -> Bool {
        var components = DateComponents()
        components.year = 2025
        components.month = 1  // January
        components.day = 30
        components.hour = 21  // 9 PM
        components.minute = 0
        components.timeZone = TimeZone(abbreviation: "MST")
        
        let targetDate = Calendar.current.date(from: components)!
        let currentDate = Date()
        
        return currentDate < targetDate
    }
}

protocol LoginEventProtocol {
    func trackLoginEvent()
}

extension LoginEventProtocol {
    func trackLoginEvent() {
        guard let accountId = AuthenticationManager.shared.session?.account.accountID,
              let payload = EventsPayloadBuilder.build(accountId: accountId,
                                                       eventAction: AccountEventAction.login,
                                                       entityId: String(accountId)) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
    
    func trackOpenArchiveMenu() {
        guard let accountId = AuthenticationManager.shared.session?.account.accountID,
              let payload = EventsPayloadBuilder.build(accountId: accountId,
                                                       eventAction: AccountEventAction.openArchiveMenu,
                                                       entityId: String(accountId),
                                                       data: ["page":"Archive Menu"]) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
}
