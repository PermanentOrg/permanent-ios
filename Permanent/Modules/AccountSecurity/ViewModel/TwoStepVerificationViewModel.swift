//
//  TwoStepVerificationViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.11.2024.

import Foundation
import SwiftUI

class TwoStepVerificationViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var isTwoFactorEnabled: Bool
    @Published var twoFactorMethods: [TwoFactorMethod]
    @Published var checkVerificationMethod: Bool = false
    @Published var refreshAccountDataRequired: Bool = false
    @Published var deleteMethodConfirmed: TwoFactorMethod?
    @Published var methodSelectedForDelete: TwoFactorMethod?
    @Published var showBottomBanner: Bool = false
    @Published var bottomBannerMessage: AuthBannerMessage = .none
    
    
    /// Initializes the view model with the current 2FA state
    /// - Parameters:
    ///   - isTwoFactorEnabled: Boolean indicating if 2FA is currently enabled
    ///   - twoFactorMethods: Array of configured 2FA methods
    /// Methods are sorted to prioritize SMS as the default method
    init(isTwoFactorEnabled: Bool, twoFactorMethods: [TwoFactorMethod]) {
        self.isTwoFactorEnabled = isTwoFactorEnabled
        self.twoFactorMethods = twoFactorMethods.sorted { method1, method2 in
            if method1.type == .sms {
                return true
            } else if method2.type == .sms {
                return false
            }
            return false
        }
    }
    
    func refreshAccountData() {
        refreshAccountDataRequired = false
        getTwoFAStatus()
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
    
    func getTwoFAStatus() {
        isLoading = true
        let operation = APIOperation(AuthenticationEndpoint.getIDPUser)
        operation.execute(in: APIRequestDispatcher()) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .json(let response, _):
                    guard let methods: [IDPUserMethodModel] = JSONHelper.convertToModel(from: response) else {
                      //  PreferencesManager.shared.set(false, forKey: Constants.Keys.StorageKeys.twoFactorAuthEnabled)
                        self?.isTwoFactorEnabled = false
                        return
                    }
                    
                    // Convert IDPUserMethodModel to TwoFactorMethod
                    self?.twoFactorMethods = methods.map { method in
                        TwoFactorMethod(methodId: method.methodId,
                                        method: method.method,
                                        value: method.value)
                    }
                    
                    // If we have any methods, 2FA is enabled
                  //  PreferencesManager.shared.set(!methods.isEmpty, forKey: Constants.Keys.StorageKeys.twoFactorAuthEnabled)
                    self?.isTwoFactorEnabled = !methods.isEmpty
                    
                case .error:
                  //  PreferencesManager.shared.set(false, forKey: Constants.Keys.StorageKeys.twoFactorAuthEnabled)
                    self?.isTwoFactorEnabled = false
                    
                default:
                   // PreferencesManager.shared.set(false, forKey: Constants.Keys.StorageKeys.twoFactorAuthEnabled)
                    self?.isTwoFactorEnabled = false
                }
            }
        }
    }
}
