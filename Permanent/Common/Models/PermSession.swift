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
        case selectedFiles
        case fileAction
        case isGridView
        case token
        case methodId
        case twoFactorId
    }

    static var currentSession: PermSession?
    
    let token: String
    
    var expirationDate: Date {
        return Date.distantFuture
    }
    var account: AccountVOData!

    /// Setting `selectedArchive` mirrors the value into App Group shared
    /// UserDefaults via `SharedSelectedArchiveStore` so the ShareExtension
    /// can fall back to this snapshot when the keychain session is unavailable.
    /// `didSet` does not fire during decoding, so the keychain → in-memory
    /// hydration path is unaffected.
    var selectedArchive: ArchiveVOData? {
        didSet { SharedSelectedArchiveStore.write(selectedArchive) }
    }

    var selectedFiles: [FileModel]?
    var fileAction: FileAction?
    
    var isGridView: Bool = false
    
    init(token: String) {
        self.token = token
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        token = try container.decode(String.self, forKey: .token)
        
        account = try container.decode(AccountVOData.self, forKey: .account)
        // `selectedArchive` is optional and is encoded as null for a logged-in user
        // who has not selected an archive yet (e.g. just registered). Use
        // decodeIfPresent so a no-archive session round-trips instead of throwing —
        // a throw here makes reloadSession() self-logout and bounce to login.
        selectedArchive = try container.decodeIfPresent(ArchiveVOData.self, forKey: .selectedArchive)
        
        selectedFiles = try container.decodeIfPresent([FileModel].self, forKey: .selectedFiles)
        fileAction = try container.decodeIfPresent(FileAction.self, forKey: .fileAction)
        
        isGridView = try container.decode(Bool.self, forKey: .isGridView)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(token, forKey: .token)
        
        try container.encode(account, forKey: .account)
        try container.encode(selectedArchive, forKey: .selectedArchive)
        
        try container.encode(selectedFiles, forKey: .selectedFiles)
        try container.encode(fileAction, forKey: .fileAction)
        
        try container.encode(isGridView, forKey: .isGridView)
    }
}

/// Mirrors the host app's currently-selected archive into App Group
/// shared UserDefaults so the ShareExtension has a fallback when the
/// keychain session is missing or doesn't carry a `selectedArchive`
/// (e.g. fresh install of the extension after a recent host login).
enum SharedSelectedArchiveStore {
    static func write(_ archive: ArchiveVOData?) {
        let key = Constants.Keys.StorageKeys.sharedSelectedArchiveKey
        guard let archive = archive else {
            PreferencesManager.shared.removeValue(forKey: key)
            return
        }
        try? PreferencesManager.shared.setCodableObject(archive, forKey: key)
    }

    static func read() -> ArchiveVOData? {
        let key = Constants.Keys.StorageKeys.sharedSelectedArchiveKey
        return (try? PreferencesManager.shared.getCodableObject(forKey: key)) ?? nil
    }
}
