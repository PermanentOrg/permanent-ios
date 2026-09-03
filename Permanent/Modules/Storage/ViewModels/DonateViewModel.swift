//
//  DonateViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 11.05.2022.
//

import Foundation

class DonateViewModel: ViewModelInterface {
    /// Asks Stela to open a Stripe PaymentIntent and hands back its client secret, or nil on any failure.
    /// Stela prices in whole US dollars, so the Apple Pay sheet must show this same integer amount.
    func createStoragePurchase(amountInUSD: Int, _ completion: @escaping ((String?) -> Void)) {
        guard amountInUSD > 0, AuthenticationManager.shared.session != nil else {
            completion(nil)
            return
        }

        let operation = APIOperation(BillingEndpoint.purchaseStorage(amountInUSD: amountInUSD))
        operation.execute(in: APIRequestDispatcher()) { [weak self] result in
            guard case .json(let json, _) = result,
                  let response: StoragePurchaseResponse = JSONHelper.decoding(from: json, with: StoragePurchaseResponse.decoder),
                  let clientSecret = response.data?.clientSecret else {
                completion(nil)
                return
            }
            self?.trackPurchaseStorage()
            completion(clientSecret)
        }
    }

    /// The whole-dollar amount typed in the donate field. Fractions are dropped; negatives, junk and
    /// values too large for an Int give 0 instead of trapping.
    func wholeDollarAmount(from text: String?) -> Int {
        guard let text, let amount = Double(text), amount > 0,
              let wholeDollars = Int(exactly: floor(amount)) else { return 0 }
        return wholeDollars
    }
    
    func storageSizeForAmount(_ amount: Double?) -> Int {
        if let amount = amount {
            if amount < .zero {
                return 0
            }
        }
        return Int(floor((amount ?? 0) / 10))
    }
    
    func trackOpenStorage() {
        guard let accountId = AuthenticationManager.shared.session?.account.accountID,
              let payload = EventsPayloadBuilder.build(accountId: accountId,
                                                       eventAction: AccountEventAction.openStorageModal,
                                                       entityId: String(accountId),
                                                       data: ["page":"Storage"]) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
    
    func trackPurchaseStorage() {
        guard let accountId = AuthenticationManager.shared.session?.account.accountID,
              let payload = EventsPayloadBuilder.build(accountId: accountId,
                                                       eventAction: AccountEventAction.purchaseStorage,
                                                       entityId: String(accountId)) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
    
}
