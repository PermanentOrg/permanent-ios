//
//  SettingsScreenViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 31.01.2024.

import SwiftUI

class SettingsScreenViewModel: ObservableObject {
    var accountData: AccountVOData?
    
    @Published var accountIsPresented: Bool = false
    @Published var storageIsPresented: Bool = false
    @Published var myArchivesIspresented: Bool = false
    @Published var invitationsIsPresented: Bool = false
    @Published var activityFeedIspresented: Bool = false
    @Published var securityIspresented: Bool = false
    @Published var legacyPlanningIspresented: Bool = false
    
    @Published var spaceRatio = 0.0
    @Published var spaceTotal: Int = 0
    @Published var spaceLeft: Int = 0
    @Published var spaceUsed: Int = 0
    @Published var spaceTotalReadable: String = ""
    @Published var spaceLeftReadable: String = ""
    @Published var spaceUsedReadable: String = ""
    
    @Published var showError: Bool = false
    
    var accountID: Int?
    @Published var accountFullName: String = ""
    @Published var accountEmail: String = ""
    @Published var selectedArchiveThumbnailURL: URL?
    
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
}
