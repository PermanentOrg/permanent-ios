//
//  RedeemCodeViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.12.2023.

import SwiftUI

class RedeemCodeViewModel: ObservableObject {
    var accountData: AccountVOData?
    @Published var invalidDataInserted: Bool = false
    @Published var isConfirmButtonDisabled: Bool = true
    @Published var redeemCode: String {
        didSet {
            if redeemCode.isEmpty {
                if firstTextFieldInput {
                    invalidDataInserted =  false
                    isConfirmButtonDisabled = true
                } else {
                    invalidDataInserted =  true
                    isConfirmButtonDisabled = true
                }
            } else {
                if redeemCode.count > 0 {
                    firstTextFieldInput = false
                }
                isConfirmButtonDisabled = false
                invalidDataInserted = false
            }
        }
    }
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var storageRedeemed: String = ""
    @Published var codeRedeemed: Bool = false
    @Published var storageRedeemedResponse: String = ""
    var firstTextFieldInput: Bool = true
    
    init(accountData: AccountVOData? = nil, redeemCode: String? = nil) {
        if let redeemCode = redeemCode {
            self.redeemCode = redeemCode
            isConfirmButtonDisabled = false
            invalidDataInserted = false
        } else {
            self.redeemCode = ""
        }

        self.accountData = accountData
    }
    
    func redeemCodeRequest() {
        isLoading = true
        let apiOperation = APIOperation(AccountEndpoint.redeemCode(code: redeemCode))
        apiOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .json(let response, _):
                    guard
                        let model: APIResults<RedeemVO> = JSONHelper.decoding(from: response, with: APIResults<RedeemVO>.decoder),
                        let data = model.results.first?.data?.first,
                        let amountRedeemed = data.promoVO?.code,
                        model.isSuccessful
                    else {
                        self?.showAlert = true
                        self?.invalidDataInserted = true
                        return
                    }
                    
                    self?.storageRedeemed = amountRedeemed
                    self?.showAlert = false
                    self?.invalidDataInserted = false
                    self?.codeRedeemed = true
                    return
                    
                case .error(_, _):
                    self?.showAlert = true
                    self?.invalidDataInserted = true
                default:
                    self?.showAlert = true
                    self?.invalidDataInserted = true
                }
            }
        }
    }
}
