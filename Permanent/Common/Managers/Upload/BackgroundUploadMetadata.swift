//
//  BackgroundUploadMetadata.swift
//  Permanent
//
//  Created by Lucian Cerbu on 23.04.2026.
//

import Foundation

/// Metadata persisted to UserDefaults so that uploads that complete after app
/// termination can still call registerRecord on relaunch.
struct BackgroundUploadMetadata: Codable {
    let fileInfoId: String
    let fileName: String
    let s3Url: String
    let destinationUrl: String
    let createdDT: String?
    let folderId: Int
    let folderLinkId: Int
    /// Absolute path string to the temp file in the app group container.
    let tempFilePath: String
    /// URLSessionTask.taskIdentifier used to match delegate callbacks.
    let taskIdentifier: Int

    // MARK: - Persistence helpers

    private static let storageKey = Constants.Keys.StorageKeys.backgroundUploadMetadataKey

    static func loadAll() -> [BackgroundUploadMetadata] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([BackgroundUploadMetadata].self, from: data)) ?? []
    }

    static func save(_ items: [BackgroundUploadMetadata]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    static func append(_ item: BackgroundUploadMetadata) {
        var all = loadAll()
        all.append(item)
        save(all)
    }

    static func remove(taskIdentifier: Int) {
        var all = loadAll()
        all.removeAll { $0.taskIdentifier == taskIdentifier }
        save(all)
    }

    static func find(taskIdentifier: Int) -> BackgroundUploadMetadata? {
        return loadAll().first { $0.taskIdentifier == taskIdentifier }
    }
}
