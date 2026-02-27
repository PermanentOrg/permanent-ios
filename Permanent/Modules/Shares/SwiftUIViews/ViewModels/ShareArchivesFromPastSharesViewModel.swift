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
        let id = UUID()
        let title: String
        let subtitle: String?
    }

    @Published var archives: [PastSharedArchive] = []
    @Published var isLoading = false

    var title: String {
        "Select an archive from past shares"
    }

    var placeholderDescription: String {
        "This screen is ready for the archive selection list implementation."
    }
}
