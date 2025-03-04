//
//  TwoStepChooseEmailViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.01.2025.

import SwiftUI

class TwoStepChooseEmailViewModel: ObservableObject {
    var containerViewModel: TwoStepConfirmationContainerViewModel
    @Published var textFieldEmail: String = ""
    @Published var isLoadingEmailValidation: Bool = false
    @Published var isLoadingCodeVerification: Bool = false
    @Published var emailAlreadyConfirmed: Bool = false
    @Published var remainingTime: Int = 0
    @Published var canResend: Bool = true
    @Published private(set) var sendCodeButtonTitle: String = "Send Code"
    
    @Published var pinCode: String = ""
    
    private var timer: Timer?
    
    init(containerViewModel: TwoStepConfirmationContainerViewModel) {
        self.containerViewModel = containerViewModel
        if let willDisable2FA = containerViewModel.methodSelectedForDelete {
            sendTwoFactorCode()
        }
    }
    
    func sendTwoFactorCode() {
        if let _ = containerViewModel.methodSelectedForDelete {
            sendTwoFactorDisableCode()
        } else {
            sendTwoFactorEnableCode()
        }
    }
    
    func sendTwoFactorEnableCode() {
        isLoadingEmailValidation = true
        
        withAnimation {
            containerViewModel.showErrorBanner = false
        }
        
        let send2FAParameters: Send2FAEnableCodeParameters = (method: "email", value: textFieldEmail)
        
        let send2FAEnableCodeOperation = APIOperation(AuthenticationEndpoint.send2FAEnableCode(parameters: send2FAParameters))
        send2FAEnableCodeOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            self?.isLoadingEmailValidation = false
            
            switch result {
            case .json(let response, _):
                self?.containerViewModel.displayBannerWithAutoClose(.successCodeSend)
                self?.startResendTimer()
                withAnimation {
                    self?.emailAlreadyConfirmed = true
                }
            case .error(let error, _):
                if let apiError = error as? APIError, apiError == .badRequest {
                    self?.containerViewModel.displayBanner(bannerErrorMessage: .invalidEmail)
                } else {
                    self?.containerViewModel.displayBanner(bannerErrorMessage: .generalError)
                }
            default:
                self?.containerViewModel.displayBanner(bannerErrorMessage: .generalError)
            }
        }
    }
    
    func sendTwoFactorDisableCode() {
        isLoadingEmailValidation = true
        
        withAnimation {
            containerViewModel.showErrorBanner = false
        }
        
        guard let deleteMethodId: String = containerViewModel.methodSelectedForDelete?.methodId else {
            self.containerViewModel.displayBanner(bannerErrorMessage: .generalError)
            return
        }
        
        let send2FAParameters: Send2FADisableCodeParameters = (method: deleteMethodId, code: nil)
        
        let send2FADisableCodeOperation = APIOperation(AuthenticationEndpoint.send2FADisableCode(parameters: send2FAParameters))
        send2FADisableCodeOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            self?.isLoadingEmailValidation = false
            
            switch result {
            case .json(let response, _):
                self?.containerViewModel.displayBannerWithAutoClose(.successCodeSend)
                self?.startResendTimer()
                withAnimation {
                    self?.emailAlreadyConfirmed = true
                }
            case .error(let error, _):
                if let apiError = error as? APIError, apiError == .badRequest {
                    self?.containerViewModel.displayBanner(bannerErrorMessage: .generalError)
                } else {
                    self?.containerViewModel.displayBanner(bannerErrorMessage: .generalError)
                }
            default:
                self?.containerViewModel.displayBanner(bannerErrorMessage: .generalError)
            }
        }
    }
    
    func verifyTwoFACode() {
        if let _ = containerViewModel.methodSelectedForDelete {
            verifyAndDisableTwoFactorCode()
        } else {
            verifyAndEnableTwoFactorCode()
        }
    }
    
    func verifyAndEnableTwoFactorCode() {
        isLoadingCodeVerification = true
        withAnimation {
            containerViewModel.showErrorBanner = false
        }
        let enable2FAParameters: Enable2FAParameters = (method: "email", value: textFieldEmail, code: pinCode)

        let enable2FACodeOperation = APIOperation(AuthenticationEndpoint.enable2FA(parameters: enable2FAParameters))
        enable2FACodeOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            self?.isLoadingCodeVerification = false
            
            switch result {
            case .json(let response, _):
                self?.containerViewModel.refreshSecurityView = true
                self?.containerViewModel.dismissContainer = true
                
            case .error(let error, _):
                if let apiError = error as? APIError, apiError == .badRequest {
                    self?.containerViewModel.displayBanner(bannerErrorMessage: .invalidPinCode)
                } else {
                    self?.containerViewModel.displayBanner(bannerErrorMessage: .generalError)
                }
            default:
                self?.containerViewModel.displayBanner(bannerErrorMessage: .generalError)
            }
        }
    }
    
    func verifyAndDisableTwoFactorCode() {
        isLoadingCodeVerification = true
        withAnimation {
            containerViewModel.showErrorBanner = false
        }
        
        guard let deleteMethodId: String = containerViewModel.methodSelectedForDelete?.methodId else {
            self.containerViewModel.displayBanner(bannerErrorMessage: .generalError)
            return
        }
        
        let disable2FAParameters: Send2FADisableCodeParameters = (method: deleteMethodId, code: pinCode)

        let disable2FACodeOperation = APIOperation(AuthenticationEndpoint.disable2FA(parameters: disable2FAParameters))
        disable2FACodeOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            self?.isLoadingCodeVerification = false
            
            switch result {
            case .json(let response, _):
                if let changingAuthMethod = self?.containerViewModel.changingAuthMethodFlow,
                   changingAuthMethod {
                    self?.containerViewModel.changingAuthMethodFlow = false
                    self?.containerViewModel.removeSelectedMethod()
                    self?.containerViewModel.setContentType(.chooseVerification)
                    self?.containerViewModel.displayBannerWithAutoClose(.successEmailDeleted)
                    
                } else {
                    self?.containerViewModel.refreshSecurityView = true
                    self?.containerViewModel.twoStepVerificationBottomBannerMessage = .successEmailDeleted
                    self?.containerViewModel.dismissContainer = true
                }
                
            case .error(let error, _):
                if let apiError = error as? APIError, apiError == .badRequest {
                    self?.containerViewModel.displayBanner(bannerErrorMessage: .invalidPinCode)
                } else {
                    self?.containerViewModel.displayBanner(bannerErrorMessage: .invalidPinCode)
                }
            default:
                self?.containerViewModel.displayBanner(bannerErrorMessage: .generalError)
            }
        }
    }
    
    private func updateButtonTitle() {
        if canResend {
            sendCodeButtonTitle = "Send Code"
        } else {
            if remainingTime == 0 {
                sendCodeButtonTitle = "Send Code"
            } else {
                let minutes = remainingTime / 60
                let seconds = remainingTime % 60
                sendCodeButtonTitle = String(format: "Resend (%02d:%02d)", minutes, seconds)
            }
        }
    }
    
    private func startResendTimer() {
        canResend = false
        remainingTime = 60
        updateButtonTitle()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if self.remainingTime > 0 {
                self.remainingTime -= 1
                self.updateButtonTitle()
            } else {
                self.canResend = true
                self.updateButtonTitle()
                timer.invalidate()
            }
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
