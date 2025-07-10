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
        let inviteCode = InviteCodeManager.shared.getAndConsumeInviteCode()
        
        let credentials: SignUpV2Credentials = (fullname, email, password, agreeUpdates, inviteCode)
        AuthenticationManager.shared.signUp(with: credentials) {[weak self] status in
            switch status {
            case .success:
                self?.signIn(then: handler)
            case .error(message: _):
                handler(.error(message: .errorMessage))
            }
        }
    }
    
    func signIn(then handler: @escaping (RegisterStatus) -> Void) {
        AuthenticationManager.shared.login(withUsername: email, password: password) { status in
            if status == .success {
                handler(.success)
            }
            else {
                handler(.error(message: .errorMessage))
            }
        }
    }

    func trackEvents() {
        guard let accountId = AuthenticationManager.shared.session?.account.accountID,
              let payload = EventsPayloadBuilder.build(accountId: accountId,
                                                       eventAction: AccountEventAction.create,
                                                       entityId: String(accountId)) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
}
