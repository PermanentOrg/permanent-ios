//
//  GiftStorageViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 31.10.2023.

import SwiftUI

class GiftStorageViewModel: ObservableObject {
    var accountData: AccountVOData?
    var spaceRatio = 0.0
    var spaceTotal: Int = 0
    var spaceLeft: Int = 0
    var spaceUsed: Int = 0
    var spaceTotalReadable: String = ""
    var spaceLeftReadable: String = ""
    
    @Published var giftAmountValue = 0 {
        didSet {
            updateGiftAmountText()
        }
    }
    @Published var amountText: String? = nil
    @Published var notEnoughStorageSpace: Bool = false
    @Published var spaceNeeded: Int = 0
    @Published var spaceLeftAfterDonation: Int = 0
    @Published var noteText: String? = ""
    @Published var didSavedNoteText: Bool = false
    @Published var giftBorderColor: Color = .galleryGray
    @Published var isSendButtonDisabled: Bool = true
    @Published var showConfirmation: Bool = false
    @Published var changesConfirmed: Bool = false {
        didSet {
            if changesConfirmed {
                sendGiftStorage()
            }
        }
    }
    @Published var emails: [String] = [] {
        didSet {
            updateGiftAmountText()
        }
    }
    @Published var sentGiftDialogError: Bool = false
    @Published var sentGiftDialogWasSuccessfull: Bool = false
    
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
    }
    
    func updateGiftAmountText() {
        spaceNeeded = giftAmountValue * emails.count * 1024 * 1024 * 1024
        spaceLeftAfterDonation = spaceLeft - spaceNeeded
        if giftAmountValue > 0,
            emails.count > 0 {
            if spaceLeftAfterDonation < 0 {
                spaceLeftAfterDonation = spaceNeeded - spaceLeft
                notEnoughStorageSpace = true
                amountText = "Insufficient storage. You need \(spaceLeftAfterDonation.bytesToReadableForm(useDecimal: true))   more."
                isSendButtonDisabled = true
                giftBorderColor = .error200
            } else {
                notEnoughStorageSpace = false
                isSendButtonDisabled =  false
                amountText = "Total gifted: \(spaceNeeded.bytesToReadableForm(useDecimal: true)) • Forecasted remaining: \(spaceLeftAfterDonation.bytesToReadableForm(useDecimal: true))"
                giftBorderColor = .galleryGray
            }
        } else {
            giftBorderColor = .galleryGray
            isSendButtonDisabled = true
            amountText = nil
        }
    }

    func sendGiftStorage() {
        let gift = GiftingModel(storageAmount: giftAmountValue, recipientEmails: emails, note: noteText)
        let endpoint = BillingEndpoint.giftStorage(gift: gift)
        let apiOperation = APIOperation(endpoint)
        
        Task {
            apiOperation.execute(in: APIRequestDispatcher()) { result in
                DispatchQueue.main.async {
                    self.changesConfirmed = false
                    switch result {
                    case .json(let response, _):
                        guard let model: ResponseGiftingModel<NoDataModel> = JSONHelper.decoding(from: response, with: ResponseGiftingModel<NoDataModel>.decoder) else {
                            self.sentGiftDialogError = true
                            return
                        }
                        //Handle success here
                        if model.storageGifted > 0 {
                            self.sentGiftDialogWasSuccessfull = true
                        } else {
                            self.sentGiftDialogError = true
                        }
                    case .error( _, _):
                        // Handle error here
                        self.sentGiftDialogError = true
                    default:
                        self.sentGiftDialogError = true
                    }
                }
            }
        }
    }
}
