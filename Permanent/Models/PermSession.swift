//
//  PermSession.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 16.06.2022.
//

import Foundation
import AppAuth

class PermSession: Codable {
    enum CodingKeys: String, CodingKey {
        case authState
        case account
        case selectedArchive
    }
    
    var authState: OIDAuthState
    var account: AccountVOData!
    
    var selectedArchive: ArchiveVOData?
    
    init(authState: OIDAuthState) {
        self.authState = authState
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let authStateData = try container.decode(Data.self, forKey: .authState)
        let decodedAuthState = try NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: authStateData)
        if decodedAuthState != nil {
            self.authState = decodedAuthState!
        } else {
            throw NSError(domain: "org.permanent", code: 401)
        }
        
        account = try container.decode(AccountVOData.self, forKey: .account)
        selectedArchive = try container.decode(ArchiveVOData.self, forKey: .selectedArchive)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let authStateData = try NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: true)
        try container.encode(authStateData, forKey: .authState)
        
        try container.encode(account, forKey: .account)
        try container.encode(selectedArchive, forKey: .selectedArchive)
    }
}
