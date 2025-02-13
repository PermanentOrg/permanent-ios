//
//  LoginSecurityViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 19.11.2024.

import Foundation
import SwiftUI

/// ViewModel that handles login security settings including two-factor authentication
/// and biometric authentication management
class LoginSecurityViewModel: ObservableObject {
    var accountData: AccountVOData?
    
    @Published var addStorageIsPresented: Bool = false
    @Published var redeemStorageIspresented: Bool = false
    @Published var isTwoStepVerificationToggleOn: Bool = false
    @Published var isSecurityToggleOn: Bool = false
    @Published var twoFactorBadgeStatus: SecurityBadgeStatus? = nil
    @Published var twoFactorMethods: [TwoFactorMethod] = []
    
    /// Initializes the view model and sets up initial state
    /// - Checks the current two-factor authentication status
    /// - Sets up biometric authentication toggle state
    init() {
        checkTwoFactorStatus()
        isSecurityToggleOn = getAuthToggleStatus()
    }
    
    /// Checks the current status of two-factor authentication by fetching
    /// the user's IDP methods from the server.
    /// Updates the UI state based on the server response.
    func checkTwoFactorStatus() {
        let operation = APIOperation(AuthenticationEndpoint.getIDPUser)
        
        operation.execute(in: APIRequestDispatcher()) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .json(let response, _):
                    guard let methods: [IDPUserMethodModel] = JSONHelper.convertToModel(from: response) else {
                        self?.updateTwoFactorStatus(enabled: false)
                        return
                    }
                    // Convert IDPUserMethodModel to TwoFactorMethod
                    withAnimation {
                        self?.twoFactorMethods = methods.map { method in
                            TwoFactorMethod(methodId: method.methodId,
                                            method: method.method,
                                            value: method.value)
                        }
                        // If we have any methods, 2FA is enabled
                        self?.updateTwoFactorStatus(enabled: !methods.isEmpty)
                    }
                    
                case .error:
                    self?.updateTwoFactorStatus(enabled: false)
                    
                default:
                    self?.updateTwoFactorStatus(enabled: false)
                }
            }
        }
    }
    
    /// Updates the UI state based on whether two-factor authentication is enabled
    /// - Parameter enabled: Boolean indicating if 2FA is enabled
    /// Updates the badge status color and text based on the enabled state
    private func updateTwoFactorStatus(enabled: Bool) {
        isTwoStepVerificationToggleOn = enabled
        if isTwoStepVerificationToggleOn {
            twoFactorBadgeStatus = SecurityBadgeStatus(text: "ON", color: .green)
        } else {
            twoFactorBadgeStatus = SecurityBadgeStatus(text: "OFF", color: .red)
        }
    }
    
    /// Returns the appropriate authentication type text based on the device's
    /// biometric capabilities
    /// - Returns: A localized string representing the auth type (Face ID or Touch ID)
    func getAuthTypeText() -> String {
        let authType = BiometryUtils.biometryInfo.name
        var authTextType: String
        switch authType {
        case "Touch ID":
            authTextType = .LogInTouchId
        case "Face ID":
            authTextType = .LogInFaceId
        default:
            authTextType = authType
        }
        return authTextType
    }
    
    /// Checks if the device has biometric authentication hardware available
    /// - Returns: Boolean indicating if biometric authentication is available
    /// Returns false if hardware is unavailable or not supported
    func getUserBiomericsStatus() -> Bool {
        let authStatus = PermanentLocalAuthentication.instance.canAuthenticate()
        return !(authStatus.error?.statusCode == LocalAuthErrors.localHardwareUnavailableError.statusCode)
    }
    
    /// Updates and saves the biometric authentication toggle status to user preferences
    /// - Parameter isEnabled: Boolean indicating if biometric auth should be enabled
    /// Also updates the UI toggle state
    func updateBiometricsStatus(isEnabled: Bool) {
        PreferencesManager.shared.set(isEnabled, forKey: Constants.Keys.StorageKeys.biometricsAuthEnabled)
        isSecurityToggleOn = isEnabled
    }
    
    /// Retrieves the current biometric authentication toggle status from preferences
    /// - Returns: Boolean indicating if biometric auth is enabled
    /// Also checks hardware availability and disables if not supported
    func getAuthToggleStatus() -> Bool {
        let authStatus = PermanentLocalAuthentication.instance.canAuthenticate()
        var biometricsAuthEnabled: Bool = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.biometricsAuthEnabled) ?? true
        
        if authStatus.error?.statusCode == LocalAuthErrors.localHardwareUnavailableError.statusCode {
            biometricsAuthEnabled = false
            // Make sure to save the disabled state if hardware is unavailable
            updateBiometricsStatus(isEnabled: false)
            return false
        }
        
        isSecurityToggleOn = biometricsAuthEnabled
        return biometricsAuthEnabled
    }
}

/// Represents the possible states after a password change attempt
enum PasswordChangeStatus {
    case success(message: String?)
    case error(message: String?)
}

/// Represents the visual status of a security feature (like 2FA)
/// with associated text and color
struct SecurityBadgeStatus: Equatable {
    let text: String
    let color: Color
}
