//
//  ChangePasswordViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.03.2025.
import SwiftUI

class ChangePasswordViewModel: ObservableObject {
    @Published var showBottomBanner: Bool = false
    @Published var bottomBannerMessage: BannerBottomMessage = .none
    @Published var showBanner: Bool = false
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    
    func verifyPasswordFields() {
        guard currentPassword.count > 7 else {
            showBanner = true
            bottomBannerMessage = .passwordTooShort
            displayBannerWithAutoClose()
            return
        }
        
        guard newPassword.count > 7 else {
            showBanner = true
            bottomBannerMessage = .passwordTooShort
            displayBannerWithAutoClose()
            return
        }
        
        guard newPassword == confirmPassword else {
            showBanner = true
            bottomBannerMessage = .passwordMismatch
            displayBannerWithAutoClose()
            return
        }
        
        changePassword()
    }
    
    func changePassword() {
        guard
            let accountId: Int = AuthenticationManager.shared.session?.account.accountID
        else {
            showBanner = true
            bottomBannerMessage = .generalError
            displayBannerWithAutoClose()
            return
        }
        
        let data = ChangePasswordCredentials(password: newPassword, passwordVerify: confirmPassword, passwordOld: currentPassword)
        let changePasswordOperation = APIOperation(AccountEndpoint.changePassword(accountId: accountId, passwordDetails: data))
        isLoading = true
        changePasswordOperation.execute(in: APIRequestDispatcher()) {[weak self] result in
            self?.isLoading = false
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<NoDataModel>.decoder
                    )
                else {
                    self?.showBanner = true
                    self?.bottomBannerMessage = .generalError
                    self?.displayBannerWithAutoClose()
                    return
                }
                guard
                    model.isSuccessful
                else {
                    let message = model.results.first?.message.first
                    let passwordChangeError = PasswordChangeError(rawValue: message ?? .errorUnknown)

                    let errorMessage: String = passwordChangeError?.description ?? .errorMessage
                    self?.showBanner = true
                    self?.bottomBannerMessage = BannerBottomMessage.custom(message: errorMessage, isErrorMessage: true)
                    self?.displayBannerWithAutoClose()
                    return
                }
                self?.showBanner = true
                self?.bottomBannerMessage = BannerBottomMessage.custom(message: "Password updated.", isErrorMessage: false)
                self?.displayBannerWithAutoClose()
                self?.currentPassword = ""
                self?.newPassword = ""
                self?.confirmPassword = ""
            case .error:
                self?.showBanner = true
                self?.bottomBannerMessage = .generalError
                self?.displayBannerWithAutoClose()
                return
                
            default:
                break
            }
        }
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

