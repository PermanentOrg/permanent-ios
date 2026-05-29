//
//  ItemVOMatching.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.05.2026.
//
//  Centralises the "is this picked file already a record in the destination
//  folder?" lookup used by Guard B (per-retry navigateMin check), the
//  end-of-batch verifier, and Guard 0 (pre-upload existence check).
//
//  Match key, in priority order:
//   1. `uploadFileName` exact equality — the server preserves this verbatim
//      from `RegisterRecordParams.filename`, so it round-trips through the
//      API exactly regardless of EXIF metadata rewrites.
//   2. extension-stripped `displayName` — fallback for older records and for
//      records whose `uploadFileName` came back nil for whatever reason.
//
//  `size` acts as an optional tiebreaker: when both sides have a positive
//  byte count, they must match. This prevents same-name-different-content
//  false positives (two distinct `Scan.pdf` in one folder) while still
//  matching against older records whose `size` is missing.
//

import Foundation

extension Array where Element == ItemVO {
    /// Returns the first record whose `uploadFileName` matches `name` exactly,
    /// or whose `displayName` matches `name` with its extension stripped.
    ///
    /// When `size` is supplied and the candidate record also has a positive
    /// `size`, the two byte counts must match; otherwise name match alone is
    /// sufficient. Zero or nil on either side is treated as "unknown" so we
    /// fall back to the name-only behaviour for legacy records.
    func record(forUploadName name: String, size: Int64? = nil) -> ItemVO? {
        let stripped = (name as NSString).deletingPathExtension
        return first { item in
            let nameMatches = item.uploadFileName == name || item.displayName == stripped
            guard nameMatches else { return false }
            if let pickedSize = size, pickedSize > 0,
               let recordSize = item.size, recordSize > 0 {
                return recordSize == pickedSize
            }
            return true
        }
    }
}

extension UploadManager {
    /// Identifies which of the picked files already have a record in the
    /// destination folder. Drives the Guard 0 pre-upload prompt so the user
    /// can choose to skip duplicates, override, or cancel before any bytes
    /// are uploaded.
    ///
    /// - Returns: empty list when no duplicates exist, OR when the folder
    ///   fetch itself fails. Falling through on fetch failure is intentional:
    ///   we don't want to block the user behind a transient network error
    ///   when we cannot determine whether duplicates exist.
    func findExistingRecords(
        archiveNo: String,
        folderLinkId: Int,
        forFiles files: [FileInfo],
        completion: @escaping (_ duplicates: [(file: FileInfo, existing: ItemVO)]) -> Void
    ) {
        guard !files.isEmpty else {
            completion([])
            return
        }
        // Pre-read picked-file byte counts once so the matcher can tiebreak
        // by size and avoid same-name-different-content false positives.
        let pickedSizes: [String: Int64] = files.reduce(into: [:]) { acc, file in
            if let bytes = (try? file.url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize {
                acc[file.id] = Int64(bytes)
            }
        }
        fetchFolderContents(archiveNo: archiveNo, folderLinkId: folderLinkId) { items in
            guard let items = items else {
                // Fetch failed — proceed as if no duplicates exist.
                completion([])
                return
            }
            let matches: [(file: FileInfo, existing: ItemVO)] = files.compactMap { file in
                items.record(forUploadName: file.name, size: pickedSizes[file.id]).map { (file, $0) }
            }
            completion(matches)
        }
    }
}
