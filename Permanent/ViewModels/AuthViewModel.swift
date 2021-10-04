//
//  LoginViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 17/09/2020.
//

import Foundation
import UIKit.UIAlertController

typealias ServerResponse = (RequestStatus) -> Void

class AuthViewModel: ViewModelInterface {
    
    var sessionProtocol: NetworkSessionProtocol = APINetworkSession()
    
    func getAccountInfo(_ completionBlock: @escaping ((AccountVOData?, Error?) -> Void) ) {
        guard let accountId: Int = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.accountIdStorageKey) else {
            completionBlock(nil, APIError.unknown)
            return
        }
        
        let getUserDataOperation = APIOperation(AccountEndpoint.getUserData(accountId: String(accountId)))
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
    
    func getAccountArchives(_ completionBlock: @escaping (([ArchiveVO]?, Error?) -> Void) ) {
        guard let accountId: Int = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.accountIdStorageKey) else {
            completionBlock(nil, APIError.unknown)
            return
        }
        
        let getAccountArchivesDataOperation = APIOperation(ArchivesEndpoint.getArchivesByAccountId(accountId: Int(accountId)))
        getAccountArchivesDataOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ArchiveVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(nil, APIError.invalidResponse)
                    return
                }
                
                let accountArchives = model.results.first?.data
                
                completionBlock(accountArchives, nil)
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
    
    func logout(then handler: @escaping ServerResponse) {
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

    func login(with credentials: LoginCredentials, then handler: @escaping (LoginStatus) -> Void) {
        let loginOperation = APIOperation(AuthenticationEndpoint.login(credentials: credentials))
        
        let apiDispatch = APIRequestDispatcher(networkSession: sessionProtocol)
        apiDispatch.ignoresMFAWarning = true
        loginOperation.execute(in: apiDispatch) { result in
            switch result {
            case .json(let response, _):
                guard let model: LoginResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }

                if model.isSuccessful == true {
                    self.saveStorageData(model)
                    handler(.success)
                } else {
                    guard
                        let message = model.results?.first?.message?.first,
                        let loginError = LoginError(rawValue: message)
                    else {
                        handler(.error(message: .errorMessage))
                        return
                    }

                    if loginError == .mfaToken {
                        self.saveStorageData(model)
                        handler(.mfaToken)
                    } else {
                        handler(.error(message: loginError.description))
                    }
                }

            case .error:
                handler(.error(message: .errorMessage))

            default:
                break
            }
        }
    }

    func forgotPassword(email: String, then handler: @escaping (String?, RequestStatus) -> Void) {
        let forgotPasswordOperation = APIOperation(AuthenticationEndpoint.forgotPassword(email: email))

        forgotPasswordOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                // TODO: Change LoginResponse and see the appropiate errors.
                let model: LoginResponse? = JSONHelper.convertToModel(from: response)
                if model?.isSuccessful == true {
                    handler(email, .success)
                } else {
                    handler(nil, .error(message: .errorMessage))
                }

            case .error:
                handler(nil, .error(message: .errorMessage))

            default:
                break
            }
        }
    }

    func signUp(with credentials: SignUpCredentials, then handler: @escaping (RequestStatus) -> Void) {
        let signUpOperation = APIOperation(AccountEndpoint.signUp(credentials: credentials))
        
        let apiDispatch = APIRequestDispatcher(networkSession: sessionProtocol)
        apiDispatch.ignoresMFAWarning = true

        signUpOperation.execute(in: apiDispatch) { result in
            switch result {
            case .json(let response, _):
                let model: SignUpResponse? = JSONHelper.convertToModel(from: response)

                if model?.isSuccessful == true {
                    handler(.success)
                } else {
                    guard
                        let message = model?.results?.first?.message?.first,
                        let signUpError = SignUpError(rawValue: message)
                    else {
                        handler(.error(message: .errorMessage))
                        return
                    }

                    handler(.error(message: signUpError.description))
                }

            case .error:
                handler(.error(message: .errorMessage))

            default:
                break
            }
        }
    }

    func createEmailInputAlert(then handler: @escaping (String?, RequestStatus) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: .resetPassword, message: nil, preferredStyle: .alert)

        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = .enterEmail
        })

        alert.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: .ok, style: .default, handler: { _ in
            guard let email: String = alert.textFields?.first?.text else { return }
            self.forgotPassword(email: email, then: handler)
        }))

        return alert
    }

    fileprivate func saveStorageData(_ response: LoginResponse) {
        PreferencesManager.shared.set(1, forKey: Constants.Keys.StorageKeys.modelVersion)
        
        if let email = response.results?.first?.data?.first?.accountVO?.primaryEmail {
            PreferencesManager.shared.set(email, forKey: Constants.Keys.StorageKeys.emailStorageKey)
        }

        if let accountId = response.results?.first?.data?.first?.accountVO?.accountID {
            PreferencesManager.shared.set(accountId, forKey: Constants.Keys.StorageKeys.accountIdStorageKey)
        }
        
        if let archiveVO = response.results?.first?.data?.first?.archiveVO {
            setCurrentArchive(archiveVO)
        } else {
            PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.archive)
        }
        
        if let archiveId = response.results?.first?.data?.first?.accountVO?.defaultArchiveID {
            PreferencesManager.shared.set(archiveId, forKey: Constants.Keys.StorageKeys.defaultArchiveId)
        }
    }
    
    func setCurrentArchive(_ archive: ArchiveVOData) {
        try? PreferencesManager.shared.setCodableObject(archive, forKey: Constants.Keys.StorageKeys.archive)
    }
    
    func getCurrentArchive() -> ArchiveVOData? {
        let archiveVO: ArchiveVOData? = try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.archive)
        
        return archiveVO
    }
    
    func refreshCurrentArchive(_ updateHandler: @escaping ((ArchiveVOData?) -> Void)) {
        getAccountArchives { [self] archives, error in
            if let defaultArchive = archives?.first(where: { $0.archiveVO?.archiveID == PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.defaultArchiveId) })?.archiveVO {
                setCurrentArchive(defaultArchive)
                
                updateHandler(defaultArchive)
            } else {
                updateHandler(nil)
            }
        }
    }
    
    func areFieldsValid (emailField: String?, passwordField: String?) -> Bool {
        return (emailField?.isNotEmpty ?? false) && (passwordField?.isNotEmpty ?? false)
    }
    
    func areFieldsValid(nameField: String?, emailField:String?, passwordField:String?) -> Bool {
        return (nameField?.isNotEmpty ?? false)&&(emailField?.isNotEmpty ?? false)&&(emailField?.isValidEmail ?? false)&&(passwordField?.count ?? 0 >= 8)
    }
    
    func bytesToReadableForm(sizeInBytes: Int,useDecimal: Bool = true) -> String {
        var unit = "B"
        var exp = 0
        var transformedSizeInBytes = Float(sizeInBytes)
        
        let byteSize: Float = 1024
        let unitsOfMeasure = ["KB", "MB", "GB", "TB", "PB"]
        
        if (sizeInBytes < Int(byteSize)) { return "\(sizeInBytes) \(unit)" }
        
        while (transformedSizeInBytes >= byteSize) {
            transformedSizeInBytes /= byteSize
            exp += 1
        }
        
        unit = unitsOfMeasure[exp - 1]
        
        if transformedSizeInBytes > 100 {
            unit = unitsOfMeasure[exp]
            transformedSizeInBytes /= 1000
        }
        
        return useDecimal ? String(format: "%.1f %@", transformedSizeInBytes, unit) : String(format: "%.0f %@", transformedSizeInBytes, unit)
    }
}

enum LoginStatus: Equatable {
    case success
    case mfaToken
    case error(message: String?)
}

enum RequestStatus: Equatable {
    case success
    case error(message: String?)
}
