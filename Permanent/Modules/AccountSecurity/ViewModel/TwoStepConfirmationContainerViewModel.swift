//
//  TwoStepVerificationViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.11.2024.

import Foundation
import SwiftUI

class TwoStepConfirmationContainerViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var isLoading: Bool = false
    @Published var showErrorBanner: Bool = false
    @Published var bannerErrorMessage: AuthBannerMessage = .none
    @Published var showAddVerificationMethod: Bool = false
    @Published var contentType: TwoStepConfirmationContentType = .confirmPassword
    @Published var insertionViewTransition: AnyTransition = .opacity
    
    func displayErrorBanner(bannerErrorMessage: AuthBannerMessage) {
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
    
    func setContentType(_ newContentType: TwoStepConfirmationContentType) {
        withAnimation {
            contentType = newContentType
        }
    }
}

enum TwoStepConfirmationContentType {
    case confirmPassword
    case chooseVerification
    case register
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
            case .none:
                return ""
            }
        }
    }
}
