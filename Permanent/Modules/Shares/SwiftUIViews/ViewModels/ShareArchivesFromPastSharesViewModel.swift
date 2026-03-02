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

        enum Thumbnail {
            case gradient(initials: String)
            case photo
        }

        let id = UUID()
        let group: Group
        let title: String
        let thumbnail: Thumbnail

        var searchableInitials: String {
            switch thumbnail {
            case .gradient(let initials):
                return initials
            case .photo:
                return ""
            }
        }
    }

    @Published var searchText = ""

    private let archives: [PastSharedArchive] = [
        PastSharedArchive(group: .mine, title: "The Heritage Archive", thumbnail: .photo),
        PastSharedArchive(group: .mine, title: "The Work & Expeditions Archive", thumbnail: .gradient(initials: "WE")),
        PastSharedArchive(group: .mine, title: "The Personal Journey Archive", thumbnail: .photo),
        PastSharedArchive(group: .other, title: "The Work & Hobby Archive", thumbnail: .gradient(initials: "WH")),
        PastSharedArchive(group: .other, title: "The Tiberiu Paliuc Long Archive", thumbnail: .gradient(initials: "TP")),
        PastSharedArchive(group: .other, title: "The Memories Archive", thumbnail: .gradient(initials: "M")),
        PastSharedArchive(group: .other, title: "The Our Home Archive", thumbnail: .gradient(initials: "OH"))
    ]

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
            || normalize($0.searchableInitials).contains(normalizedFilter)
        }
    }

    var myArchives: [PastSharedArchive] {
        filteredArchives.filter { $0.group == .mine }
    }

    var otherArchives: [PastSharedArchive] {
        filteredArchives.filter { $0.group == .other }
    }
}
