//
//  PermSession.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 16.06.2022.
//

import Foundation

class PermSession: Codable {
    enum CodingKeys: String, CodingKey {
        case account
        case selectedArchive
        case selectedFile
        case fileAction
        case isGridView
        case token
    }

    static var currentSession: PermSession?
    
    let token: String
    var expirationDate: Date {
        return Date.distantFuture
    }
    var account: AccountVOData!
    
    var selectedArchive: ArchiveVOData?
    
    var selectedFile: FileViewModel?
    var fileAction: FileAction?
    
    var isGridView: Bool = false
    
    init(token: String) {
        self.token = token
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        token = try container.decode(String.self, forKey: .token)
        
        account = try container.decode(AccountVOData.self, forKey: .account)
        selectedArchive = try container.decode(ArchiveVOData.self, forKey: .selectedArchive)
        
        selectedFile = try container.decodeIfPresent(FileViewModel.self, forKey: .selectedFile)
        fileAction = try container.decodeIfPresent(FileAction.self, forKey: .fileAction)
        
        isGridView = try container.decode(Bool.self, forKey: .isGridView)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(token, forKey: .token)
        
        try container.encode(account, forKey: .account)
        try container.encode(selectedArchive, forKey: .selectedArchive)
        
        try container.encode(selectedFile, forKey: .selectedFile)
        try container.encode(fileAction, forKey: .fileAction)
        
        try container.encode(isGridView, forKey: .isGridView)
    }
}
