//
//  DonateViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 11.05.2022.
//

import Foundation

class DonateViewModel: ViewModelInterface {
    var accountId: Int? {
        return AuthenticationManager.shared.session?.account.accountID
    }
    
    var accountName: String? {
        return AuthenticationManager.shared.session?.account.fullName
    }
    
    var email: String? {
        return AuthenticationManager.shared.session?.account.primaryEmail
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
        let json = paymentSheetPayload(accountId: accountId, email: email, amount: amount, isAnonymous: isAnonymous, name: name)

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
        if let amount = amount {
            if amount < .zero {
                return 0
            }
        }
        return Int(floor((amount ?? 0) / 10))
    }
    
    func paymentSheetPayload(accountId: Int, email: String, amount: Int, isAnonymous: Bool, name: String) -> [String: Any] {
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
