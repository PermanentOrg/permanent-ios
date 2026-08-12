//
//  ExtensionUploadManager.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.06.2022.
//

import Foundation

/// Hand-off queue for files the ShareExtension sends to the app. Both processes read-modify-write
/// it, which `NSLock` cannot serialize, so it is a coordinated file rather than UserDefaults.
class ExtensionUploadManager {
    static let appSuiteGroup = "group.permanent.org.share"
    /// Legacy App-Group UserDefaults key. Read as a fallback until the first
    /// write migrates it into `storeFileName`, then removed.
    static let savedFilesKey = "group.permanent.org.share.files"
    /// Filename of the coordinated queue inside the App-Group container.
    private static let storeFileName = "share-upload-queue.dat"

    static let shared = ExtensionUploadManager()

    /// The coordinated queue file, shared through the App-Group container. `nil` only if the
    /// entitlement is missing.
    private var storeURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.appSuiteGroup)?
            .appendingPathComponent(Self.storeFileName)
    }

    // MARK: - Public API

    /// Replaces the whole queue, coordinated so it can't tear a concurrent read. Use `append(_:)` to
    /// add — saving a locally-read list drops whatever the other process wrote meanwhile.
    func save(files: [FileInfo]) throws {
        try mutate { _ in files }
    }

    /// Atomically merges `files` ahead of what is queued, across processes. A read-then-save pair
    /// leaves a gap between them, which is the cross-process lost-update window.
    func append(_ files: [FileInfo]) throws {
        try mutate { existing in files + existing }
    }

    func savedFiles() throws -> [FileInfo] {
        guard let url = storeURL else { return legacyFiles() }

        var result: [FileInfo] = []
        var thrownError: Error?
        var coordError: NSError?
        NSFileCoordinator(filePresenter: nil)
            .coordinate(readingItemAt: url, options: [], error: &coordError) { readURL in
                do {
                    // Until the first write migrates it, the queue is still in the legacy UserDefaults key — fall
                    // back to it so an upgrade with pending shares doesn't read empty.
                    if FileManager.default.fileExists(atPath: readURL.path) {
                        result = try readStore(at: readURL)
                    } else {
                        result = legacyFiles()
                    }
                } catch {
                    thrownError = error
                }
            }
        if let coordError { throw coordError }
        // A present-but-undecodable file surfaces as an error (the caller retries)
        // rather than a silent empty queue — see readStore(at:).
        if let thrownError { throw thrownError }
        return result
    }

    /// Drop the entire queue (both the coordinated file and the legacy key).
    func clearSavedFiles() {
        PreferencesManager().removeValue(forKey: Self.savedFilesKey)

        guard let url = storeURL else { return }
        NSFileCoordinator(filePresenter: nil)
            .coordinate(writingItemAt: url, options: .forDeleting, error: nil) { deleteURL in
                try? FileManager.default.removeItem(at: deleteURL)
            }
    }

    func clearSavedFiles(_ files: [FileInfo]) throws {
        try mutate { $0.filter { !files.contains($0) } }
    }

    // MARK: - Cross-process-atomic read-modify-write

    /// The one primitive every mutation goes through: read fresh, transform, write back, all inside
    /// an exclusive write coordination so the other process cannot interleave.
    private func mutate(_ transform: ([FileInfo]) -> [FileInfo]) throws {
        guard let url = storeURL else {
            throw NSError(domain: "ExtensionUploadManager", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "App-Group container unavailable"])
        }

        var thrownError: Error?
        var coordError: NSError?
        NSFileCoordinator(filePresenter: nil)
            .coordinate(writingItemAt: url, options: [], error: &coordError) { writeURL in
                do {
                    // The first write adopts any legacy UserDefaults queue as its base, carrying pending shares
                    // forward. A corrupt file throws rather than reading empty, which would overwrite real shares.
                    let fileExists = FileManager.default.fileExists(atPath: writeURL.path)
                    let current = fileExists ? try readStore(at: writeURL) : legacyFiles()

                    let next = transform(current)
                    let data = try encodeStore(next)
                    try data.write(to: writeURL, options: .atomic)

                    // Retire the legacy key only once the queue is durably in the coordinated file: if the write
                    // above threw, the key stays and migration retries.
                    if !fileExists {
                        PreferencesManager().removeValue(forKey: Self.savedFilesKey)
                    }
                } catch {
                    thrownError = error
                }
            }
        if let coordError { throw coordError }
        if let thrownError { throw thrownError }
    }

    // MARK: - Archive (same format as the legacy UserDefaults store)

    private func encodeStore(_ files: [FileInfo]) throws -> Data {
        NSKeyedArchiver.setClassName("Permanent.FileInfo", for: FileInfo.self)
        NSKeyedArchiver.setClassName("Permanent.FolderInfo", for: FolderInfo.self)
        return try NSKeyedArchiver.archivedData(withRootObject: NSArray(array: files),
                                                requiringSecureCoding: false)
    }

    /// Strict decode: absent or empty is an empty queue, but an undecodable file throws rather than
    /// returning `[]`. Callers must treat the throw as "leave the bytes alone".
    private func readStore(at url: URL) throws -> [FileInfo] {
        let data = try Data(contentsOf: url)
        guard !data.isEmpty else { return [] }

        NSKeyedUnarchiver.setClass(FileInfo.self, forClassName: "Permanent.FileInfo")
        NSKeyedUnarchiver.setClass(FolderInfo.self, forClassName: "Permanent.FolderInfo")
        guard
            let nsFiles = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? NSArray,
            let files = nsFiles as? [FileInfo]
        else {
            throw NSError(domain: "ExtensionUploadManager", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Upload queue file is present but could not be decoded"])
        }
        return files
    }

    /// Lenient decode, only for the legacy UserDefaults blob during migration: an unreadable value
    /// degrades to empty rather than blocking the move to the coordinated file.
    private func decode(_ data: Data) -> [FileInfo] {
        NSKeyedUnarchiver.setClass(FileInfo.self, forClassName: "Permanent.FileInfo")
        NSKeyedUnarchiver.setClass(FolderInfo.self, forClassName: "Permanent.FolderInfo")
        guard
            let nsFiles = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? NSArray,
            let files = nsFiles as? [FileInfo]
        else { return [] }
        return files
    }

    /// The queue as stored by an older build (App-Group UserDefaults). Read-only;
    /// the key is cleared by `mutate`/`clearSavedFiles` once migrated.
    private func legacyFiles() -> [FileInfo] {
        guard let data: Data = PreferencesManager().getValue(forKey: Self.savedFilesKey) else { return [] }
        return decode(data)
    }
}
