//
//  RedeemCodeViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.12.2023.

import SwiftUI

class RedeemCodeViewModel: ObservableObject {
    var accountData: AccountVOData?
    @Published var invalidDataInserted: Bool = false
    @Published var redeemCode: String
    @Published var isLoading: Bool = false
    
    init(accountData: AccountVOData? = nil) {
        self.accountData = accountData
        self.redeemCode = ""
    }
    
    func redeemCodeRequest() {
        ///To do, API call for redeem code.
    }
}
