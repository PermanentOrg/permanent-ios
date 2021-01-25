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
    var actualCsrf: String?
    weak var viewDelegate: SecurityViewModelDelegate?
}

protocol SecurityViewModelDelegate: ViewModelDelegateInterface {
    func changePassword(with accountId: String, data: ChangePasswordCredentials, csrf: String, then handler: @escaping (PasswordChangeStatus) -> Void)
    func getNewCsrf(then handler: @escaping (Bool) -> Void)
    func getUserBiomericsStatus() -> Bool
    func getAuthToggleStatus() -> Bool
    func getAuthTypeText() -> String
}

extension SecurityViewModel: SecurityViewModelDelegate {
    func changePassword(with accountId: String, data: ChangePasswordCredentials, csrf: String, then handler: @escaping (PasswordChangeStatus) -> Void) {
        let changePasswordOperation = APIOperation(AccountEndpoint.changePassword(accountId: accountId, passwordDetails: data, csrf: csrf))

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
            case .error:
                handler(.error(message: .errorMessage))

            default:
                break
            }
        }
    }

    func getNewCsrf(then handler: @escaping (Bool) -> Void) {
        let getNewCsrfOperation = APIOperation(AccountEndpoint.getValidCsrf)

        getNewCsrfOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<NoDataModel>.decoder
                    ),
                    model.isSuccessful

                else {
                    self.actualCsrf = .errorMessage
                    return
                }
                self.actualCsrf = model.csrf
                handler(true)
                return
            case .error:
                handler(false)
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
