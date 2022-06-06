//
//  DonateViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 11.05.2022.
//

import Foundation

class DonateViewModel: ViewModelInterface {
    var accountId: Int? {
        return PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.accountIdStorageKey)
    }
    
    var accountName: String? {
        return PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.nameStorageKey)
    }
    
    var email: String? {
        return PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.emailStorageKey)
    }
    
    var isAnonymous: Bool = false
    
    func createPaymentIntent(amount: Int, _ completion: @escaping ((String?) -> Void)) {
        guard let accountId = accountId, let name = accountName, let email = email else {
            completion(nil)
            return
        }
        
        var req = URLRequest(url: URL(string: "\(APIEnvironment.defaultEnv.donationBaseURL)/payment-sheet")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let json = jsonInitWithValues(accountId: accountId, email: email, amount: amount, isAnonymous: isAnonymous, name: name)

        req.httpBody = try? JSONSerialization.data(withJSONObject: json, options: [])
        
        let dt = URLSession.shared.dataTask(with: req) { data, urlresponse, error in
            if let data = data, let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let clientSecret = jsonObj["paymentIntent"] as? String
                completion(clientSecret)
            } else {
                completion(nil)
            }
        }
        dt.resume()
    }
    
    func storageSizeForAmount(_ amount: Double?) -> Int {
        return Int(floor((amount ?? 0) / 10))
    }
    
    func jsonInitWithValues(accountId: Int, email: String, amount: Int, isAnonymous: Bool, name: String) -> [String: Any] {
        let json: [String: Any] = [
            "accountId": accountId,
            "email": email,
            "amount": amount,
            "anonymous": isAnonymous,
            "name": name
        ]
        return json
    }
}
