//
//  ShareFindArchiveByEmailViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.02.2026.
//

import Foundation
import SwiftUI

@MainActor
final class ShareFindArchiveByEmailViewModel: ObservableObject {
    struct ArchiveResult: Identifiable {
        let id = UUID()
        let archiveID: Int?
        let initials: String
        let name: String
        let thumbnailURL: String?
    }

    enum SearchOutcome {
        case idle
        case found([ArchiveResult])
        case noAccount(String)
    }

    typealias SearchProvider = (String, @escaping (SearchOutcome) -> Void) -> Void

    @Published var searchText = ""
    @Published private(set) var submittedSearchEmail: String?
    @Published private(set) var searchOutcome: SearchOutcome = .idle
    @Published private(set) var isSearching = false
    @Published private(set) var accessedArchiveIDs: Set<Int> = []

    func setAccessedArchiveIDs(_ ids: Set<Int>) {
        accessedArchiveIDs = ids
    }

    func hasAccess(_ archive: ArchiveResult) -> Bool {
        guard let id = archive.archiveID else { return false }
        return accessedArchiveIDs.contains(id)
    }

    func sortedByAccess(_ archives: [ArchiveResult]) -> [ArchiveResult] {
        archives.filter { !hasAccess($0) } + archives.filter { hasAccess($0) }
    }

    private var searchOperation: APIOperation?
    private let searchProvider: SearchProvider?

    init(searchProvider: SearchProvider? = nil) {
        self.searchProvider = searchProvider
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedSearchText: String {
        sanitizedEmail(trimmedSearchText).lowercased()
    }

    private func sanitizedEmail(_ input: String) -> String {
        let hiddenScalars = CharacterSet(charactersIn: "\u{200B}\u{200C}\u{200D}\u{2060}\u{FEFF}")
        return input.unicodeScalars
            .filter { !hiddenScalars.contains($0) }
            .map(String.init)
            .joined()
    }

    var visibleSearchOutcome: SearchOutcome {
        guard let submittedSearchEmail = submittedSearchEmail,
              submittedSearchEmail == normalizedSearchText else {
            return .idle
        }
        return searchOutcome
    }

    var visibleOutcomeState: Int {
        switch visibleSearchOutcome {
        case .idle:
            return 0
        case .found:
            return 1
        case .noAccount:
            return 2
        }
    }

    @discardableResult
    func performSearch() -> Bool {
        let emailToSearch = normalizedSearchText
        guard emailToSearch.isValidEmail else {
            submittedSearchEmail = nil
            searchOutcome = .idle
            return false
        }

        submittedSearchEmail = emailToSearch
        isSearching = true
        withAnimation(.easeInOut(duration: 0.2)) {
            searchOutcome = .idle
        }

        if let searchProvider {
            searchProvider(emailToSearch) { [weak self] outcome in
                guard let self else { return }
                self.isSearching = false
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.searchOutcome = outcome
                }
            }
            return true
        }

        searchOperation?.cancel()
        searchOperation = APIOperation(SearchEndpoint.archiveByEmail(email: emailToSearch))
        searchOperation?.execute(in: APIRequestDispatcher()) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                defer {
                    self.searchOperation = nil
                    self.isSearching = false
                }

                switch result {
                case .json(let response, _):
                    guard let model: APIResults<ArchiveVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<ArchiveVO>.decoder
                    ), model.isSuccessful else {
                        self.setNoAccount(for: emailToSearch)
                        return
                    }

                    let archives = model.results
                        .flatMap { $0.data ?? [] }
                        .compactMap { $0.archiveVO }
                        .map { self.mapArchiveResult(from: $0) }

                    if archives.isEmpty {
                        self.setNoAccount(for: emailToSearch)
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.searchOutcome = .found(archives)
                        }
                    }

                case .error:
                    self.setNoAccount(for: emailToSearch)

                default:
                    self.setNoAccount(for: emailToSearch)
                }
            }
        }

        return true
    }

    func clearSearch() {
        searchOperation?.cancel()
        searchOperation = nil
        searchText = ""
        isSearching = false
        withAnimation(.easeInOut(duration: 0.2)) {
            submittedSearchEmail = nil
            searchOutcome = .idle
        }
    }

    func handleTextChanged() {
        if submittedSearchEmail != nil {
            withAnimation(.easeInOut(duration: 0.2)) {
                searchOutcome = .idle
            }
        }
    }

    func reset() {
        searchOperation?.cancel()
        searchOperation = nil
        searchText = ""
        submittedSearchEmail = nil
        searchOutcome = .idle
        isSearching = false
    }

    private func setNoAccount(for email: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            searchOutcome = .noAccount(email)
        }
    }

    private func mapArchiveResult(from archive: ArchiveVOData) -> ArchiveResult {
        let fullName = archive.fullName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"
        return ArchiveResult(
            archiveID: archive.archiveID,
            initials: initials(for: fullName),
            name: formattedArchiveName(from: fullName),
            thumbnailURL: archive.preferredThumbnailURL
        )
    }

    private func formattedArchiveName(from fullName: String) -> String {
        let lowercased = fullName.lowercased()
        if lowercased.hasPrefix("the ") && lowercased.hasSuffix(" archive") {
            return fullName
        }
        return "The \(fullName) Archive"
    }

    private func initials(for fullName: String) -> String {
        let parts = fullName
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }

        if parts.count >= 2 {
            let first = parts[0].prefix(1)
            let second = parts[1].prefix(1)
            return (first + second).uppercased()
        }

        if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }

        return "A"
    }
}
