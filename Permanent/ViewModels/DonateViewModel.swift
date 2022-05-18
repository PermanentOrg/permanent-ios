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
    
    var email: String? {
        return PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.emailStorageKey)
    }
    
    func createPaymentIntent(amount: Int, _ completion: @escaping ((String?) -> Void)) {
        guard let accountId = accountId, let email = email else {
            completion(nil)
            return
        }
        
        var req = URLRequest(url: URL(string: "\(APIEnvironment.defaultEnv.donationBaseURL)/payment-sheet")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let json: [String: Any] = [
            "accountId": accountId,
            "email": email,
            "amount": amount
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: json, options: [])
        
        let dt = URLSession.shared.dataTask(with: req) { data, urlresponse, error in
            if let data = data {
                let jsonObj = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
                 
                let clientSecret = jsonObj["paymentIntent"] as? String
                completion(clientSecret)
            }
        }
        dt.resume()
    }
}
