//
//  ItemVOMatching.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.05.2026.
//
//  Centralises the "is this picked file already a record in the destination
//  folder?" lookup used by the per-retry folder-existence check, the
//  end-of-batch verifier, and the pre-upload duplicate prompt.
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
    /// The first record matching `name` on `uploadFileName`, or on `displayName` with its extension
    /// stripped. `size` must agree when both sides have one; unknown on either side means name-only.
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

#if !APP_EXTENSION
extension FolderChildV2Data {
    /// Adapts a V2 child into the minimal `ItemVO` the dedupe matcher reads, so a V2 listing flows
    /// through it unchanged. Nil for a child that won't decode; callers drop nils.
    func toMatchableItemVO() -> ItemVO? {
        var payload: [String: Any] = [:]
        if let uploadFileName = uploadFileName { payload["uploadFileName"] = uploadFileName }
        if let displayName = displayName { payload["displayName"] = displayName }
        if let size = size { payload["size"] = size }
        return JSONHelper.decoding(from: payload, with: ItemVO.decoder)
    }
}

extension Array where Element == FolderChildV2Data {
    /// The dedupe pipeline over a V2 listing: records only, since dedupe matches files and never
    /// subfolders. Here so production and the tests exercise the same expression.
    func toMatchableItemVOs() -> [ItemVO] {
        filter { !$0.isFolder }.compactMap { $0.toMatchableItemVO() }
    }
}
#endif

extension UploadManager {
    /// Which of the picked files already exist in the destination, driving the pre-upload prompt.
    /// - Returns: empty when there are no duplicates, and also when the fetch itself fails — a
    ///   transient network error must not block the upload behind an unanswerable question.
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
        // Destination folderId (Stela numeric id) for the V2 listing; all picked files
        // in a batch target the same folder. Missing/≤0 → fetchFolderContents uses V1.
        let folderId = files.first?.folder.folderId ?? -1
        fetchFolderContents(archiveNo: archiveNo, folderLinkId: folderLinkId, folderId: folderId) { items in
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
