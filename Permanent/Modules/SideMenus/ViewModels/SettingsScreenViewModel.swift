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
                    EventsManager.resetUser()
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
}
