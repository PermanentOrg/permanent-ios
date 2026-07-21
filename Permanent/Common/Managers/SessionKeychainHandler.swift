//
//  SessionKeychainHandler.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 22.07.2022.
//

import Foundation
import KeychainSwift

class SessionKeychainHandler {
    static let keychainAuthDataKey = "org.permanent.authData"

    enum SessionKeychainError: Error {
        /// The keychain write returned failure (e.g. an access-group/entitlement mismatch).
        case writeFailed
    }

    let keychain: KeychainSwift = {
        let kc = KeychainSwift()
        if let group = KeychainAccessGroupResolver.sharedSessionGroup {
            kc.accessGroup = group
        }
        return kc
    }()

    func savedSession() throws -> PermSession? {
        guard let authData = keychain.getData(Self.keychainAuthDataKey) else {
            return nil
        }
        return try JSONDecoder().decode(PermSession.self, from: authData)
    }

    func saveSession(_ session: PermSession) throws {
        let authData = try JSONEncoder().encode(session)
        // KeychainSwift.set deletes-then-adds internally, but returns false on a failed
        // write. Ignoring that silently drops the session (user looks logged in this run,
        // but is logged out on next launch) — surface it so callers can react.
        guard keychain.set(authData, forKey: Self.keychainAuthDataKey) else {
            throw SessionKeychainError.writeFailed
        }
    }

    func clearSession() {
        keychain.delete(Self.keychainAuthDataKey)
    }
}

/// Probes the keychain at runtime to discover the access group iOS assigns
/// the calling process by default — i.e. the first entry of the process's
/// `keychain-access-groups` entitlement, resolved to `<TEAMID>.<group>`.
///
/// We need the resolved string so the host app and ShareExtension can set
/// `KeychainSwift.accessGroup` *explicitly* and converge on the same physical
/// keychain item regardless of iOS default-group quirks.
enum KeychainAccessGroupResolver {
    private static let probeAccount = "_PermanentAccessGroupProbe"
    private static var cached: String?
    private static var didProbe = false

    static var sharedSessionGroup: String? {
        if didProbe { return cached }
        didProbe = true
        cached = probeAccessGroup()
        return cached
    }

    private static func probeAccessGroup() -> String? {
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: probeAccount,
            kSecAttrService as String: probeAccount
        ]

        // Clean up any stale probe from previous launches before re-adding.
        _ = SecItemDelete(baseQuery as CFDictionary)

        var addQuery = baseQuery
        addQuery[kSecValueData as String] = Data([0x01])
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess || addStatus == errSecDuplicateItem else {
            return nil
        }

        var readQuery = baseQuery
        readQuery[kSecReturnAttributes as String] = kCFBooleanTrue
        readQuery[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let readStatus = SecItemCopyMatching(readQuery as CFDictionary, &result)
        _ = SecItemDelete(baseQuery as CFDictionary)

        guard readStatus == errSecSuccess,
              let attrs = result as? [String: Any],
              let group = attrs[kSecAttrAccessGroup as String] as? String else {
            return nil
        }
        return group
    }
}
