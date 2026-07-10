//
//  ExtensionUploadManager.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.06.2022.
//

import Foundation

/// Shared hand-off queue for files the ShareExtension sends to the main app.
///
/// The main app (`UploadManager`) and the ShareExtension run in **separate
/// processes**, yet both read-modify-write this queue: the app clears completed
/// uploads (every ~30s and after each upload) while the extension appends newly
/// shared files. An in-memory lock (`NSLock`) can't serialize across processes,
/// so concurrent writers could clobber each other — a shared file silently
/// dropped from the queue and never uploaded, or duplicated.
///
/// The queue therefore lives in a single file in the App-Group container and
/// every access goes through `NSFileCoordinator`: coordinated *reads* for
/// snapshots, and a coordinated *write barrier* for the read-modify-write in
/// `mutate`, which makes each read-transform-write atomic with respect to the
/// other process.
///
/// UserDefaults (where the queue used to live) is intentionally **not** used for
/// the source of truth: it isn't covered by file coordination and has
/// cross-process cache lag, so it can't be made race-free in place. Any queue
/// left in the old UserDefaults key by a previous build is migrated into the
/// coordinated file on the first write (byte-for-byte, only after the file write
/// succeeds), and reads fall back to it until then — so nothing in flight at
/// upgrade time is lost.
class ExtensionUploadManager {
    static let appSuiteGroup = "group.permanent.org.share"
    /// Legacy App-Group UserDefaults key. Read as a fallback until the first
    /// write migrates it into `storeFileName`, then removed.
    static let savedFilesKey = "group.permanent.org.share.files"
    /// Filename of the coordinated queue inside the App-Group container.
    private static let storeFileName = "share-upload-queue.dat"

    static let shared = ExtensionUploadManager()

    /// The coordinated queue file, shared by both processes via the App-Group
    /// container. `nil` only if the App-Group entitlement is missing (it isn't,
    /// for the app and the extension).
    private var storeURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.appSuiteGroup)?
            .appendingPathComponent(Self.storeFileName)
    }

    // MARK: - Public API

    /// Replace the whole queue. Coordinated so it can't tear a concurrent read
    /// or be lost against a concurrent write. Callers that add to the queue
    /// should use `append(_:)` — a bare `save` of a locally-read list would drop
    /// anything the other process wrote in the meantime.
    func save(files: [FileInfo]) throws {
        try mutate { _ in files }
    }

    /// Atomically merge `files` ahead of whatever is already queued, spanning
    /// processes. Replaces the old read-`savedFiles()`-then-`save()` sequence,
    /// whose gap between the read and the write was the cross-process
    /// lost-update window.
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
                    // Before the first write migrates it, the queue is still in the
                    // legacy UserDefaults key — fall back to it so an upgrade with
                    // pending shares doesn't read an empty queue.
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

    /// The single primitive every mutation goes through. Runs `transform` on the
    /// queue inside an exclusive write coordination — read fresh, transform,
    /// write back — so the other process can't interleave and clobber the write.
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
                    // First write for this container adopts any queue left in the
                    // legacy UserDefaults key as its base, so migration carries
                    // the pending shares forward instead of overwriting them.
                    //
                    // A present-but-undecodable file must NOT be read as empty:
                    // transform([]) would then be written over real pending shares
                    // — the exact data loss this store exists to prevent. readStore
                    // throws on a corrupt file, which aborts this write with the
                    // on-disk bytes left intact (see the catch below).
                    let fileExists = FileManager.default.fileExists(atPath: writeURL.path)
                    let current = fileExists ? try readStore(at: writeURL) : legacyFiles()

                    let next = transform(current)
                    let data = try encodeStore(next)
                    try data.write(to: writeURL, options: .atomic)

                    // Retire the legacy key only after the queue is durably in the
                    // coordinated file; if the write above threw, the key is left
                    // intact and migration retries next time.
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

    /// Decode the coordinated file **strictly**: an absent or empty file is an
    /// empty queue, but a non-empty file that fails to unarchive throws rather
    /// than silently returning `[]`. Callers must treat that throw as "leave the
    /// bytes alone", never as "the queue is empty" — otherwise a corrupt file
    /// would be overwritten with an empty queue and its pending shares lost.
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

    /// Lenient decode used only for the legacy UserDefaults blob during migration.
    /// The legacy key is being retired, so an unreadable value degrades to an
    /// empty queue instead of blocking the move to the coordinated file.
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
