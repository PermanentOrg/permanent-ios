//
//  LoginViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 17/09/2020.
//

import Foundation
import UIKit

typealias ServerResponse = (RequestStatus) -> Void

class AuthViewModel: ViewModelInterface, LoginEventProtocol {
    var sessionProtocol: NetworkSessionProtocol = APINetworkSession()
    static let updateArchiveSettingsChevron = Notification.Name("AuthViewModel.updateArchiveSettingsChevron")
    var archiveSetingsWasPressed: Bool = false {
        didSet {
            NotificationCenter.default.post(name: Self.updateArchiveSettingsChevron, object: self, userInfo: nil)
        }
    }
    var accountData: AccountVOData?
    
    func getAccountInfo(_ completionBlock: @escaping ((AccountVOData?, Error?) -> Void) ) {
        guard let accountId: Int = AuthenticationManager.shared.session?.account.accountID else {
            completionBlock(nil, APIError.unknown)
            return
        }
        
        let getUserDataOperation = APIOperation(AccountEndpoint.getUserData(accountId: accountId))
        getUserDataOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<AccountVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(nil, APIError.invalidResponse)
                    return
                }
                
                let accountData = model.results[0].data?[0].accountVO
                completionBlock(accountData, nil)
               
                return
                
            case .error:
                completionBlock(nil, APIError.invalidResponse)
                return
                
            default:
                completionBlock(nil, APIError.invalidResponse)
                return
            }
        }
    }
    
    func deletePushToken(then handler: @escaping ServerResponse) {
        guard let token: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.fcmPushTokenKey)
        else {
            handler(.success)
            return
        }
        
        let deleteTokenParams = (token)
        let deleteTokenOperation = APIOperation(DeviceEndpoint.delete(params: deleteTokenParams))

        deleteTokenOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: AuthResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }

                if model.isSuccessful == true {
                    handler(.success)
                } else {
                    handler(.error(message: .errorMessage))
                }

            case .error:
                handler(.error(message: .errorMessage))

            default:
                break
            }
        }
    }
    
    func login(withUsername username: String?, password: String?, then handler: @escaping (LoginStatus) -> Void) {
        guard let email = username, let password = password, areFieldsValid(emailField: email, passwordField: password) else {
            handler(.error(message: .invalidFields))
            return
        }
        
        AuthenticationManager.shared.login(withUsername: email, password: password) { status in
            switch status {
            case .success, .mfaToken, .unknown:
                handler(status)
                
            case .error(message: _):
                handler(.error(message: .errorMessage))
            }
        }
    }
    
    func forgotPassword(withEmail email: String?, then handler: @escaping (RequestStatus) -> Void) {
        guard let email = email else {
            handler(.error(message: .invalidFields))
            return
        }
        
        AuthenticationManager.shared.forgotPassword(withEmail: email) { status in
            handler(status)
        }
    }
    
    func signUp(with credentials: SignUpCredentials, then handler: @escaping (RequestStatus) -> Void) {
        AuthenticationManager.shared.signUp(with: credentials) { status in
            switch status {
            case .success:
                handler(.success)
                
            case .error(message: _):
                handler(.error(message: .errorMessage))
            }
        }
    }
    
    func logout(then handler: @escaping ServerResponse) {
        AuthenticationManager.shared.logout()
        
        let logoutOperation = APIOperation(AuthenticationEndpoint.logout)

        logoutOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: AuthResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }

                if model.isSuccessful == true {
                    handler(.success)
                } else {
                    handler(.error(message: .errorMessage))
                }

            case .error:
                handler(.error(message: .errorMessage))

            default:
                break
            }
        }
    }
    
    func setCurrentArchive(_ archive: ArchiveVOData) {
        AuthenticationManager.shared.session?.selectedArchive = archive
    }
    
    func getCurrentArchive() -> ArchiveVOData? {
        let archiveVO: ArchiveVOData? = AuthenticationManager.shared.session?.selectedArchive
        
        return archiveVO
    }
    
    func areFieldsValid(nameField: String?, emailField: String?, passwordField: String?) -> Bool {
        return (nameField?.isNotEmpty ?? false) && (emailField?.isNotEmpty ?? false) && (emailField?.isValidEmail ?? false) && (passwordField?.count ?? 0 >= 8)
    }
    
    func areFieldsValid(emailField: String?, passwordField: String?) -> Bool {
        return (emailField?.isNotEmpty ?? false) && (emailField?.isValidEmail ?? false) && (passwordField?.count ?? 0 >= 8)
    }
    
    func areFieldsValid(emailField: String?) -> Bool {
        return (emailField?.isNotEmpty ?? false) && (emailField?.isValidEmail ?? false)
    }
    
    func hasLegacyPermissions() -> Bool {
        if let selectedArchivePermission = AuthenticationManager.shared.session?.selectedArchive?.permissions(), selectedArchivePermission.contains(.legacyPlanning) {
            return true
        } else {
            return false
        }
    }
}

enum LoginStatus: Equatable {
    case success
    case mfaToken
    case unknown
    case error(message: String?)
}

enum RequestStatus: Equatable {
    case success
    case error(message: String?)
}
