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
        case selectedFile
        case fileAction
        case isGridView
    }
    
    var authState: OIDAuthState
    var account: AccountVOData!
    
    var selectedArchive: ArchiveVOData?
    
    var selectedFile: FileViewModel?
    var fileAction: FileAction?
    
    var isGridView: Bool = false
    
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
        
        selectedFile = try container.decodeIfPresent(FileViewModel.self, forKey: .selectedFile)
        fileAction = try container.decodeIfPresent(FileAction.self, forKey: .fileAction)
        
        isGridView = try container.decode(Bool.self, forKey: .isGridView)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        let authStateData = try NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: true)
        try container.encode(authStateData, forKey: .authState)
        
        try container.encode(account, forKey: .account)
        try container.encode(selectedArchive, forKey: .selectedArchive)
        
        try container.encode(selectedFile, forKey: .selectedFile)
        try container.encode(fileAction, forKey: .fileAction)
        
        try container.encode(isGridView, forKey: .isGridView)
    }
}
