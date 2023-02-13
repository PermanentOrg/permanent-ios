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
    static let updateArchiveSettingsChevron = Notification.Name("AuthViewModel.updateArchiveSettingsChevron")
    var archiveSetingsWasPressed: Bool = false {
        didSet {
            NotificationCenter.default.post(name: Self.updateArchiveSettingsChevron, object: self, userInfo: nil)
        }
    }
    
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
    
    func bytesToReadableForm(sizeInBytes: Int, useDecimal: Bool = true) -> String {
        var unit = "B"
        var exp = 0
        var transformedSizeInBytes = Float(sizeInBytes)
        
        let byteSize: Float = 1024
        let unitsOfMeasure = ["KB", "MB", "GB", "TB", "PB"]
        
        if sizeInBytes < Int(byteSize) { return "\(sizeInBytes) \(unit)" }
        
        while transformedSizeInBytes >= byteSize {
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
