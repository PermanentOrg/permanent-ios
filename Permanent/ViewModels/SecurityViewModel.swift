//
//  SecurityViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 13.01.2021.
//

import Foundation
import UIKit

typealias ChangePasswordCredentials = (password: String, passwordVerify: String, passwordOld: String)

class SecurityViewModel: ViewModelInterface {
    weak var delegate: SecurityViewModelDelegate?
    weak var viewDelegate: SecurityViewModelViewDelegate?
}

protocol SecurityViewModelDelegate: ViewModelDelegateInterface {
    func changePassword(with accountId: Int, data: ChangePasswordCredentials, then handler: @escaping (PasswordChangeStatus) -> Void)
    func getUserBiomericsStatus() -> Bool
    func getAuthToggleStatus() -> Bool
    func getAuthTypeText() -> String
}

protocol SecurityViewModelViewDelegate: ViewModelDelegateInterface {
    func passwordUpdated(success: Bool)
}

extension SecurityViewModel: SecurityViewModelDelegate {
    func changePassword(with accountId: Int, data: ChangePasswordCredentials, then handler: @escaping (PasswordChangeStatus) -> Void) {
        let changePasswordOperation = APIOperation(AccountEndpoint.changePassword(accountId: accountId, passwordDetails: data))

        changePasswordOperation.execute(in: APIRequestDispatcher()) { result in

            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<NoDataModel>.decoder
                    )
                else {
                    handler(.error(message: .errorMessage))
                    self.viewDelegate?.passwordUpdated(success: false)
                    return
                }
                guard
                    model.isSuccessful
                else {
                    let message = model.results.first?.message.first
                    let passwordChangeError = PasswordChangeError(rawValue: message ?? .errorUnknown)
                    handler(.error(message: passwordChangeError?.description))
                    return
                }
                handler(.success(message: .passwordChangedSuccessfully))
                self.viewDelegate?.passwordUpdated(success: true)
            case .error:
                handler(.error(message: .errorMessage))
                self.viewDelegate?.passwordUpdated(success: false)

            default:
                break
            }
        }
    }

    func getAuthTypeText() -> String {
        let authType = BiometryUtils.biometryInfo.name
        var authTextType: String
        switch authType {
        case "Touch ID":
            authTextType = .logInWith + .LogInTouchId
        case "Face ID":
            authTextType = .logInWith + .LogInFaceId
        default:
            authTextType = authType
        }
        return authTextType
    }

    func getUserBiomericsStatus() -> Bool {
        let authStatus = PermanentLocalAuthentication.instance.canAuthenticate()
        return !(authStatus.error?.statusCode == LocalAuthErrors.localHardwareUnavailableError.statusCode)
    }

    func getAuthToggleStatus() -> Bool {
        let authStatus = PermanentLocalAuthentication.instance.canAuthenticate()
        var biometricsAuthEnabled: Bool = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.biometricsAuthEnabled) ?? true
        if authStatus.error?.statusCode == LocalAuthErrors.localHardwareUnavailableError.statusCode {
            biometricsAuthEnabled = false
        }

        return biometricsAuthEnabled
    }
}

enum PasswordChangeStatus {
    case success(message: String?)
    case error(message: String?)
}
