//
//  SettingsScreenViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 31.01.2024.

import SwiftUI

class SettingsScreenViewModel: ObservableObject {
    private var accountData: AccountVOData?
    @Published var spaceRatio = 0.0
    @Published var spaceTotal: Int = 0
    @Published var spaceLeft: Int = 0
    @Published var spaceUsed: Int = 0
    @Published var spaceTotalReadable: String = ""
    @Published var spaceLeftReadable: String = ""
    @Published var spaceUsedReadable: String = ""
    
    private var accountID: Int?
    @Published var accountFullName: String = ""
    @Published var accountEmail: String = ""
    @Published var selectedArchiveThumbnailURL: URL?

    @Published var showError: Bool = false
    @Published var isLoading: Bool = false
    @Published var loggedOut: Bool = false
    
    @Published var twoFactorAuthenticationEnabled: Bool? = true
    @Published var isLoading2FAStatus: Bool = false
    @Published var twoFactorMethods: [TwoFactorMethod] = []
    
    init() {
        getAccountInfo { error in
            if error != nil {
                self.showError = true
            } else {
                self.getAccountDetails()
                self.getStorageSpaceDetails()
                self.getCurrentArchiveThumbnail()
            }
        }
            getTwoFAStatus()
    }
    
    func getAccountInfo(_ completionBlock: @escaping ((Error?) -> Void) ) {
        guard let accountId: Int = AuthenticationManager.shared.session?.account.accountID else {
            completionBlock(APIError.unknown)
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
                    completionBlock(APIError.invalidResponse)
                    return
                }
                if let accountDataVO = model.results[0].data?[0].accountVO {
                    self.accountData = accountDataVO
                    completionBlock(nil)
                    return
                }
                completionBlock(APIError.invalidResponse)
                return
                
            default:
                completionBlock(APIError.invalidResponse)
                return
            }
        }
    }
    
    func getTwoFAStatus() {
        let operation = APIOperation(AuthenticationEndpoint.getIDPUser)
        isLoading2FAStatus = true
        operation.execute(in: APIRequestDispatcher()) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading2FAStatus = false
                switch result {
                case .json(let response, _):
                    guard let methods: [IDPUserMethodModel] = JSONHelper.convertToModel(from: response) else {
                        PreferencesManager.shared.set(false, forKey: Constants.Keys.StorageKeys.twoFactorAuthEnabled)
                        self?.twoFactorAuthenticationEnabled = false
                        return
                    }
                    
                    // Convert IDPUserMethodModel to TwoFactorMethod
                    self?.twoFactorMethods = methods.map { method in
                        TwoFactorMethod(methodId: method.methodId,
                                        method: method.method,
                                        value: method.value)
                    }
                    
                    // If we have any methods, 2FA is enabled
                    PreferencesManager.shared.set(!methods.isEmpty, forKey: Constants.Keys.StorageKeys.twoFactorAuthEnabled)
                    self?.twoFactorAuthenticationEnabled = !methods.isEmpty
                    
                case .error:
                    PreferencesManager.shared.set(false, forKey: Constants.Keys.StorageKeys.twoFactorAuthEnabled)
                    self?.twoFactorAuthenticationEnabled = false
                    
                default:
                    PreferencesManager.shared.set(false, forKey: Constants.Keys.StorageKeys.twoFactorAuthEnabled)
                    self?.twoFactorAuthenticationEnabled = false
                }
            }
        }
    }
    
    func getAccountDetails() {
        guard let accountData = accountData else { return }
        
        accountID = accountData.accountID
        accountFullName = accountData.fullName ?? ""
        accountEmail = accountData.primaryEmail ?? ""
    }
    
    func getStorageSpaceDetails() {
        guard let accountData = accountData else { return }
        
        spaceTotal = (accountData.spaceTotal ?? 0)
        spaceLeft = (accountData.spaceLeft ?? 0)
        spaceUsed = spaceTotal - spaceLeft
        
        spaceRatio = Double(spaceUsed) / Double(spaceTotal)
        
        spaceTotalReadable = spaceTotal.bytesToReadableForm(useDecimal: false)
        spaceLeftReadable = spaceLeft.bytesToReadableForm(useDecimal: true)
        spaceUsedReadable = spaceUsed.bytesToReadableForm(useDecimal: true)
    }
    
    func getCurrentArchiveThumbnail() {
        guard let archiveThumbString = AuthenticationManager.shared.session?.selectedArchive?.thumbURL500 else { return }
        selectedArchiveThumbnailURL = URL(string: archiveThumbString)
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
                    PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.twoFactorAuthEnabled)
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
    
    func signOut() {
        isLoading = true
        deletePushToken(then: { status in
            self.logout(then: { status in
                self.isLoading = false
                switch status {
                case .success:
                    self.loggedOut = true
                    
                case .error(let message):
                        self.showError = true
                }
            })
        })
    }
    
    func trackEvents() {
        guard let accountId = AuthenticationManager.shared.session?.account.accountID,
              let payload = EventsPayloadBuilder.build(accountId: accountId,
                                                       eventAction: AccountEventAction.openAccountMenu,
                                                       entityId: String(accountId),
                                                       data: ["page":"Account Menu"]) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
}
