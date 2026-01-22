//
//  SharePreviewViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.01.2026
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SharePreviewViewModel: ObservableObject {
    // MARK: - Published
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var shareName: String = ""
    @Published var sharedByName: String = ""
    @Published var archiveName: String = ""
    @Published var thumbnailURL: String?
    @Published var items: [SharePreviewItem] = []
    @Published var currentArchive: ArchiveVOData?
    @Published var availableArchives: [ArchiveVOData] = []
    @Published var shareStatus: ShareStatus = .pending

    // MARK: - Private
    private let shareToken: String
    private var cancellables = Set<AnyCancellable>()
    private let repository: SharePreviewRepositoryProtocol

    // Navigation callbacks
    var onNavigateToFolder: ((NavigateMinParams) -> Void)?

    // MARK: - Init
    init(shareToken: String,
         repository: SharePreviewRepositoryProtocol = SharePreviewRepository()) {
        self.shareToken = shareToken
        self.repository = repository
        self.currentArchive = AuthenticationManager.shared.session?.selectedArchive
    }

    // MARK: - Public
    func start() {
        Task { await loadShareData() }
        loadAvailableArchives()
    }

    func selectArchive(_ archive: ArchiveVOData) {
        currentArchive = archive
    }

    func viewInArchive() {
        // Delegate navigation to presenter
        guard let shareDetails = try? buildShareDetailsFromState() else { return }

        // Determine navigation params similar to UIKit flow
        let archiveNo = currentArchive?.archiveNbr ?? ""

        if let folderLinkId = shareDetails.folderLinkId, folderLinkId > 0 {
            let params: NavigateMinParams = (archiveNo: archiveNo, folderLinkId: folderLinkId, folderName: shareDetails.sharedFileName)
            onNavigateToFolder?(params)
            return
        }

        if let parentFolderLinkId = shareDetails.parentFolderLinkId, parentFolderLinkId > 0 {
            let params: NavigateMinParams = (archiveNo: archiveNo, folderLinkId: parentFolderLinkId, folderName: "Containing Folder")
            onNavigateToFolder?(params)
            return
        }

        // fallback: no navigation
    }

    // MARK: - Private
    private func loadAvailableArchives() {
        if let archives = AuthenticationManager.shared.session?.account.archives {
            availableArchives = archives
        }
    }

    private func buildShareDetailsFromState() throws -> ShareDetails {
        // Attempt to create a minimal ShareDetails struct from current state
        var details = ShareDetails()
        details.sharedFileName = shareName
        details.archiveName = archiveName
        // NOTE: Additional fields should be filled when real response is parsed
        return details
    }

    private func loadShareData() async {
        isLoading = true
        do {
            let resp = try await repository.fetchSharePreview(shareToken: shareToken)
            parseShareData(resp)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    private func parseShareData(_ data: SharePreviewData) {
        shareName = data.shareName
        sharedByName = data.sharedByName
        archiveName = data.archiveName
        thumbnailURL = data.thumbnailURL
        shareStatus = data.status

        items = data.items.map { SharePreviewItem(id: $0.id, name: $0.name, thumbnailURL: $0.thumbnailURL, isFolder: $0.isFolder, type: $0.type) }
    }
}

// MARK: - Supporting Protocols & Mocks

// Repository protocol and a lightweight mock implementation are declared here.
// Shared model types live in `SharePreviewModels.swift`.

protocol SharePreviewRepositoryProtocol {
    func fetchSharePreview(shareToken: String) async throws -> SharePreviewData
}

struct SharePreviewRepository: SharePreviewRepositoryProtocol {
    func fetchSharePreview(shareToken: String) async throws -> SharePreviewData {
        return SharePreviewData.mock()
    }
}