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
        let rawName: String
        let title: String
        let initials: String
        let thumbnailURL: String?
    }

    @Published var searchText = ""
    @Published private(set) var myArchivesList: [PastSharedArchive] = []
    @Published private(set) var otherArchivesList: [PastSharedArchive] = []
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

    private func filtered(_ list: [PastSharedArchive]) -> [PastSharedArchive] {
        guard !normalizedFilter.isEmpty else { return list }
        return list.filter {
            normalize($0.rawName).contains(normalizedFilter)
            || normalize($0.initials).contains(normalizedFilter)
        }
    }

    var myArchives: [PastSharedArchive] {
        filtered(myArchivesList)
    }

    var otherArchives: [PastSharedArchive] {
        filtered(otherArchivesList)
    }

    func fetchArchives() {
        guard let accountId = PermSession.currentSession?.account.accountID,
              let archiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID else { return }

        isLoading = true

        let group = DispatchGroup()
        var fetchedMyArchives: [PastSharedArchive] = []
        var fetchedOtherArchives: [PastSharedArchive] = []

        group.enter()
        let accountOp = APIOperation(ArchivesEndpoint.getArchivesByAccountId(accountId: accountId))
        accountOp.execute(in: APIRequestDispatcher()) { [weak self] result in
            defer { group.leave() }
            guard let self else { return }

            if case .json(let response, _) = result,
               let model: APIResults<ArchiveVO> = JSONHelper.decoding(
                   from: response,
                   with: APIResults<NoDataModel>.decoder
               ),
               model.isSuccessful {

                let accountArchives = model.results.first?.data ?? []
                var archiveMap: [Int: ArchiveVOData] = [:]

                for archive in accountArchives {
                    guard let data = archive.archiveVO,
                          data.accessRole == "access.role.owner",
                          data.status != .pending && data.status != .unknown,
                          let id = data.archiveID,
                          id != archiveId else { continue }

                    if archiveMap[id] == nil || (archiveMap[id]?.fullName == nil && data.fullName != nil) {
                        archiveMap[id] = data
                    }
                }

                fetchedMyArchives = archiveMap.values
                    .sorted { ($0.fullName ?? "") < ($1.fullName ?? "") }
                    .map { self.makePastSharedArchive(from: $0, group: .mine) }
            }
        }

        group.enter()
        let relationOp = APIOperation(RelationEndpoint.getAll(archiveId: archiveId))
        relationOp.execute(in: APIRequestDispatcher()) { [weak self] result in
            defer { group.leave() }
            guard let self else { return }

            if case .json(let response, _) = result,
               let model: APIResults<RelationVO> = JSONHelper.decoding(
                   from: response,
                   with: APIResults<NoDataModel>.decoder
               ),
               model.isSuccessful {

                let relations = model.results.first?.data ?? []
                var archiveMap: [Int: ArchiveVOData] = [:]

                for relation in relations {
                    guard let data = relation.relationVO?.relationArchiveVO,
                          data.status != .pending && data.status != .unknown,
                          let id = data.archiveID,
                          id != archiveId else { continue }

                    if archiveMap[id] == nil || (archiveMap[id]?.fullName == nil && data.fullName != nil) {
                        archiveMap[id] = data
                    }
                }

                fetchedOtherArchives = archiveMap.values
                    .sorted { ($0.fullName ?? "") < ($1.fullName ?? "") }
                    .map { self.makePastSharedArchive(from: $0, group: .other) }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            let myArchiveIDs = Set(fetchedMyArchives.compactMap { $0.archiveID })
            let dedupedOther = fetchedOtherArchives.filter { !myArchiveIDs.contains($0.archiveID ?? -1) }

            self.myArchivesList = fetchedMyArchives
            self.otherArchivesList = dedupedOther
            self.isLoading = false
        }
    }

    private func makePastSharedArchive(from archive: ArchiveVOData, group: PastSharedArchive.Group) -> PastSharedArchive {
        let fullName = archive.fullName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"

        return PastSharedArchive(
            group: group,
            archiveID: archive.archiveID,
            rawName: fullName,
            title: formattedArchiveName(from: fullName),
            initials: initials(for: fullName),
            thumbnailURL: archive.thumbURL200 ?? archive.thumbURL500
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
