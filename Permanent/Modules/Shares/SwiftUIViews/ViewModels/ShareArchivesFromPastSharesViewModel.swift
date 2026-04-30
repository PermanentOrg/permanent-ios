//
//  ShareArchivesFromPastSharesViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.02.2026.
//

import SwiftUI

@MainActor
final class ShareArchivesFromPastSharesViewModel: ObservableObject {
    struct PastSharedArchive: Identifiable {
        enum Group {
            case mine
            case other
        }

        let id = UUID()
        let group: Group
        let archiveID: Int?
        let title: String
        let initials: String
        let thumbnailURL: String?
    }

    @Published var searchText = ""
    @Published private(set) var archives: [PastSharedArchive] = []
    @Published private(set) var isLoading = false

    var title: String {
        "Select archive from past shares"
    }

    private var normalizedFilter: String {
        normalize(searchText)
    }

    private func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "&", with: "")
    }

    private var filteredArchives: [PastSharedArchive] {
        guard !normalizedFilter.isEmpty else { return archives }
        return archives.filter {
            normalize($0.title).contains(normalizedFilter)
            || normalize($0.initials).contains(normalizedFilter)
        }
    }

    var myArchives: [PastSharedArchive] {
        filteredArchives.filter { $0.group == .mine }
    }

    var otherArchives: [PastSharedArchive] {
        filteredArchives.filter { $0.group == .other }
    }

    func fetchArchives() {
        guard let accountId = PermSession.currentSession?.account.accountID else { return }

        isLoading = true

        let operation = APIOperation(ArchivesEndpoint.getArchivesByAccountId(accountId: accountId))
        operation.execute(in: APIRequestDispatcher()) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isLoading = false

                switch result {
                case .json(let response, _):
                    guard
                        let model: APIResults<ArchiveVO> = JSONHelper.decoding(
                            from: response,
                            with: APIResults<NoDataModel>.decoder
                        ),
                        model.isSuccessful
                    else { return }

                    let accountArchives = model.results.first?.data ?? []
                    var archiveMap: [Int: ArchiveVOData] = [:]

                    for archive in accountArchives {
                        guard let archiveVOData = archive.archiveVO,
                              archiveVOData.status != .pending && archiveVOData.status != .unknown,
                              let archiveID = archiveVOData.archiveID else { continue }

                        if let existing = archiveMap[archiveID] {
                            if existing.fullName == nil && archiveVOData.fullName != nil {
                                archiveMap[archiveID] = archiveVOData
                            }
                        } else {
                            archiveMap[archiveID] = archiveVOData
                        }
                    }

                    let currentArchiveID = AuthenticationManager.shared.session?.selectedArchive?.archiveID

                    self.archives = archiveMap.values
                        .sorted { ($0.fullName ?? "") < ($1.fullName ?? "") }
                        .map { archive in
                            let fullName = archive.fullName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"
                            let isMine = archive.accessRole == "access.role.owner"

                            return PastSharedArchive(
                                group: isMine ? .mine : .other,
                                archiveID: archive.archiveID,
                                title: self.formattedArchiveName(from: fullName),
                                initials: self.initials(for: fullName),
                                thumbnailURL: archive.thumbURL200 ?? archive.thumbURL500
                            )
                        }

                default:
                    break
                }
            }
        }
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
