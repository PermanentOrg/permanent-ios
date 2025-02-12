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
    
    func verifyAndEnableReceivedTwoFactorEnableCode() {
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
    
    func testEnableCode() {
        isLoadingCodeVerification = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.5) { [weak self] in
            self?.isLoadingCodeVerification = false
            self?.containerViewModel.dismissContainer = true
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
