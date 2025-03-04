//
//  AuthenticatorContainerViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.09.2024.

import Foundation
import SwiftUI

class AuthenticatorContainerViewModel: ObservableObject {
    @Published var accountWasDeleted: Bool = false
    @Published var contentType: AuthContentType
    @Published var firstViewContentType: AuthContentType = .login
    @Published var isLoading: Bool = false
    @Published var insertionViewTransition: AnyTransition = .opacity
    
    @Published var bannerErrorMessage: AuthBannerMessage = .none
    @Published var maintenanceTopBannerWasDisplayed: Bool = false
    @Published var showErrorBanner: Bool = false
    
    var username: String = ""
    var password: String = ""
    var mfaSession: MFASession?
    
    init(contentType: AuthContentType = .login) {
        self.contentType = contentType
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
    
    func setContentType(_ newContentType: AuthContentType) {
        if Constants.Design.isPhone {
            switch contentType {
            case .login:
                insertionViewTransition = .move(edge: .trailing)
            case .register:
                if newContentType == .login {
                    insertionViewTransition = .move(edge: .leading)
                } else {
                    insertionViewTransition = .move(edge: .trailing)
                }
            case .verifyIdentity:
                insertionViewTransition = .move(edge: .trailing)
            case .forgotPassword:
                if newContentType == .forgotPasswordConfirmation {
                    insertionViewTransition = .move(edge: .trailing)
                } else {
                    insertionViewTransition = .move(edge: .leading)
                }
            case .forgotPasswordConfirmation:
                insertionViewTransition = .move(edge: .trailing)
            default:
                insertionViewTransition = .move(edge: .trailing)
            }
        }
        withAnimation {
            contentType = newContentType
        }
    }
}

enum AuthContentType {
    case login
    case register
    case verifyIdentity
    case forgotPassword
    case forgotPasswordConfirmation
    case none
}
