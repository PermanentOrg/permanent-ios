//
//  StorageViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.12.2023.

import Foundation

class StorageViewModel: ObservableObject {
    var accountData: AccountVOData?
    var spaceRatio = 0.0
    var spaceTotal: Int = 0
    var spaceLeft: Int = 0
    var spaceUsed: Int = 0
    var spaceTotalReadable: String = ""
    var spaceLeftReadable: String = ""
    var spaceUsedReadable: String = ""
    @Published var showRedeemNotif: Bool = false
    @Published var reddemAmmountConverted: String = ""
    @Published var redeemAmmountString: String = "" {
        didSet {
            if let reddemAmmountInt = Int(redeemAmmountString),
               reddemAmmountInt > 0 {
                reddemAmmountConverted = (reddemAmmountInt * 1024 * 1024).bytesToReadableForm(useDecimal: false)
                showRedeemNotif = true
            }
        }
    }
    
    init(accountData: AccountVOData?) {
        self.accountData = accountData
        
        getStorageSpaceDetails()
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
}
