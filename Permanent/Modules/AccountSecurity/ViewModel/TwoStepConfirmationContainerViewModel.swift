//
//  TwoStepVerificationViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.11.2024.

import Foundation
import SwiftUI

enum TwoStepConfirmationContentType {
    case confirmPassword
    case chooseVerification
    case register
    case choosePhoneNumber
    case chooseEmail
    case none
    
    func screenTitle() -> String {
        withAnimation {
            switch self {
            case .confirmPassword:
                return "Confirm Password"
            case .chooseVerification:
                return "Choose Verification"
            case .register:
                return "Register"
            case .chooseEmail:
                return "Add email verification method"
            case .choosePhoneNumber:
                return "Add text verification method"
            case .none:
                return ""
            }
        }
    }
}

class TwoStepConfirmationContainerViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var isLoading: Bool = false
    @Published var showErrorBanner: Bool = false
    @Published var bannerErrorMessage: AuthBannerMessage = .none
    @Published var showAddVerificationMethod: Bool = false
    @Published var contentType: TwoStepConfirmationContentType = .confirmPassword
    @Published var insertionViewTransition: AnyTransition = .opacity
    @Published var dismissContainer: Bool = false
    
    func displayBanner(bannerErrorMessage: AuthBannerMessage) {
        if showErrorBanner {
            withAnimation {
                showErrorBanner = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
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
    
    func displayBannerWithAutoClose(_ bannerErrorMessage: AuthBannerMessage) {
        displayBanner(bannerErrorMessage: bannerErrorMessage)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            withAnimation {
                self?.showErrorBanner = false
            }
        }
    }
    
    func setContentType(_ newContentType: TwoStepConfirmationContentType) {
        withAnimation {
            contentType = newContentType
        }
    }
}
