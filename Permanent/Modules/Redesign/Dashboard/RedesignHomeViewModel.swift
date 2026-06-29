//
//  RedesignHomeViewModel.swift
//  Permanent
//
//  Drives the populated "My Dashboard" tab (Stage 6). REUSES the existing
//  `ArchivesViewModel` for all networking — no reimplementation:
//    load:   ArchivesViewModel.getAccountArchives  (ArchivesEndpoint.getArchivesByAccountId)
//    switch: ArchivesViewModel.changeArchive(_:)    (ArchivesEndpoint.change → setCurrentArchive)
//
//  `getAccountArchives` itself reads the account id from
//  `PermSession.currentSession?.account?.accountID`, and already filters out
//  pending/unknown archives into `allArchives`. We additionally keep only
//  `status == .ok` and map each `ArchiveVOData` to a presentational
//  `RedesignArchiveItem` (computing initials from the name).
//
//  Only reachable when `DashboardRedesign.isEnabled`.
//

import Foundation
import SwiftUI

@MainActor
final class RedesignHomeViewModel: ObservableObject {
    @Published var archives: [RedesignArchiveItem] = []
    @Published var isLoading = false

    private let archivesViewModel = ArchivesViewModel()
    private var archiveChangeObserver: NSObjectProtocol?

    init() {
        // Refresh when the current archive changes anywhere (drawer switch,
        // settings, accept-invitation, share flow). The greeting (`firstName`)
        // reads the session and recomputes on the publish from `load()`.
        archiveChangeObserver = NotificationCenter.default.addObserver(
            forName: ArchivesViewModel.didChangeArchiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.load() }
        }
    }

    deinit {
        if let archiveChangeObserver {
            NotificationCenter.default.removeObserver(archiveChangeObserver)
        }
    }

    /// Greeting name: the session account's first name if available, else "there".
    var firstName: String {
        if let full = AuthenticationManager.shared.session?.account?.fullName,
           let first = full.split(separator: " ").first, !first.isEmpty {
            return String(first)
        }
        return "there"
    }

    /// Loads the account's archives and maps the `status == .ok` ones to
    /// `RedesignArchiveItem`s for the widget.
    func load() {
        isLoading = true
        archivesViewModel.getAccountArchives { [weak self] _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                guard error == nil else {
                    // Keep whatever we already had; the widget still shows "Create".
                    return
                }
                let okArchives = self.archivesViewModel.allArchives
                    .filter { $0.status == .ok }
                self.archives = okArchives.compactMap(Self.makeItem)
            }
        }
    }

    /// Switches the current archive to `item` by delegating to the existing
    /// `changeArchive` choreography (which calls the change endpoint and updates
    /// the persisted session + posts `didChangeArchiveNotification`).
    /// `completion` reports success on the main queue.
    func selectArchive(_ item: RedesignArchiveItem, completion: @escaping (Bool) -> Void) {
        guard let archive = archivesViewModel.allArchives.first(where: { $0.archiveID == item.id }) else {
            completion(false)
            return
        }
        archivesViewModel.changeArchive(archive) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }

    // MARK: - Mapping

    private static func makeItem(from data: ArchiveVOData) -> RedesignArchiveItem? {
        guard let id = data.archiveID else { return nil }
        let name = data.fullName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let display = (name?.isEmpty == false) ? name! : "Untitled Archive"
        return RedesignArchiveItem(
            id: id,
            fullName: display,
            initials: initials(from: display)
        )
    }

    /// Computes initials from the archive name: the first letters of the first
    /// two significant words, skipping a leading "The" and a trailing "Archive".
    static func initials(from fullName: String) -> String {
        let stopWords: Set<String> = ["the", "archive", "an", "a", "of", "and"]
        let significant = fullName
            .split(whereSeparator: { $0 == " " || $0 == "-" || $0 == "_" })
            .map(String.init)
            .filter { !stopWords.contains($0.lowercased()) }

        let source = significant.isEmpty
            ? fullName.split(separator: " ").map(String.init)
            : significant

        let letters = source.prefix(2).compactMap { word -> Character? in
            word.first(where: { $0.isLetter || $0.isNumber })
        }

        if letters.isEmpty {
            // Last-resort: first character of the trimmed name.
            if let ch = fullName.first(where: { $0.isLetter || $0.isNumber }) {
                return String(ch).uppercased()
            }
            return "?"
        }
        return letters.map { String($0).uppercased() }.joined()
    }
}
