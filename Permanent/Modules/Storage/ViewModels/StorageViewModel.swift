//
//  StorageViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.12.2023.

import Foundation

class StorageViewModel: ObservableObject {
    var accountData: AccountVOData?
    
    @Published var addStorageIsPresented: Bool = false
    @Published var giftStorageIsPresented: Bool = false
    @Published var redeemStorageIspresented: Bool = false
    @Published var showRedeemNotifView = false
    
    @Published var redeemCodeFromUrl: String?
    @Published var spaceRatio = 0.0
    @Published var spaceTotal: Int = 0
    @Published var spaceLeft: Int = 0
    @Published var spaceUsed: Int = 0
    @Published var spaceTotalReadable: String = ""
    @Published var spaceLeftReadable: String = ""
    @Published var spaceUsedReadable: String = ""
    @Published var showError: Bool = false
    @Published var showRedeemCodeView: Bool = false
    @Published var showRedeemNotif: Bool = false
    @Published var redeemAmmountConverted: String = ""
    @Published var redeemAmmountInt: Int = 0 {
        didSet {
            let ammountAdded = redeemAmmountInt * 1024 * 1024
            if redeemAmmountInt > 0 {
                redeemAmmountConverted = ammountAdded.bytesToReadableForm(useDecimal: true)
                addInTotalSpace(spaceToAdd: ammountAdded)
                showRedeemNotif = true
            }
        }
    }
    
    init(reddemCode: String? = nil) {
        self.redeemCodeFromUrl = reddemCode
        if reddemCode != nil {
            redeemStorageIspresented = true
        }
        
        getAccountInfo { error in
            if error != nil {
                self.showError = true
            } else {
                self.getStorageSpaceDetails()
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
    
    func addInTotalSpace(spaceToAdd: Int) {
        spaceTotal = spaceTotal + spaceToAdd
        spaceRatio = Double(spaceUsed) / Double(spaceTotal)
        spaceTotalReadable = spaceTotal.bytesToReadableForm(useDecimal: false)
    }
}
