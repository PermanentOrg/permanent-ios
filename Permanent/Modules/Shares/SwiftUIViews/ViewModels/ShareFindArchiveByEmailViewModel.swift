//
//  ShareFindArchiveByEmailViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.02.2026.
//

import SwiftUI

@MainActor
final class ShareFindArchiveByEmailViewModel: ObservableObject {
    struct ArchiveResult: Identifiable {
        let id = UUID()
        let initials: String
        let name: String
    }

    enum SearchOutcome {
        case idle
        case found([ArchiveResult])
        case noAccount(String)
    }

    @Published var searchText = ""
    @Published private(set) var submittedSearchEmail: String?
    @Published private(set) var searchOutcome: SearchOutcome = .idle

    private let mockArchiveResults: [ArchiveResult] = [
        ArchiveResult(initials: "TP", name: "The Tiberiu Paliuc Long Archive"),
        ArchiveResult(initials: "F", name: "The Family Archive"),
        ArchiveResult(initials: "V", name: "The VSP Archive")
    ]

    private let mockEmailsWithArchives: Set<String> = [
        "tiberiupaliuc@gmail.com"
    ]

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

        withAnimation(.easeInOut(duration: 0.2)) {
            submittedSearchEmail = emailToSearch
            if mockEmailsWithArchives.contains(emailToSearch) {
                searchOutcome = .found(mockArchiveResults)
            } else {
                searchOutcome = .noAccount(emailToSearch)
            }
        }
        return true
    }

    func clearSearch() {
        searchText = ""
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
        searchText = ""
        submittedSearchEmail = nil
        searchOutcome = .idle
    }
}
