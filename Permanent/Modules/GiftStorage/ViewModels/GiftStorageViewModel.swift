//
//  GiftStorageViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 31.10.2023.

import SwiftUI

class GiftStorageViewModel: ObservableObject {
    var accountData: AccountVOData?
    var spaceRatio = 0.0
    var spaceTotalReadable: String = ""
    var spaceLeftReadable: String = ""
    
    @Published var emails: [String] = []
    
    init(accountData: AccountVOData?) {
        self.accountData = accountData
        
        getStorageSpaceDetails()
    }
    
    func getStorageSpaceDetails() {
        guard let accountData = accountData else { return }
        
        let spaceTotal = (accountData.spaceTotal ?? 0)
        let spaceLeft = (accountData.spaceLeft ?? 0)
        let spaceUsed = spaceTotal - spaceLeft
        
        spaceRatio = Double(spaceUsed) / Double(spaceTotal)
        
        spaceTotalReadable = spaceTotal.bytesToReadableForm(useDecimal: false)
        spaceLeftReadable = spaceLeft.bytesToReadableForm()
    }
}
