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
    @Published var displayMode: SharePreviewDisplayMode = .loading

    // MARK: - Private
    private let shareToken: String
    private var cancellables = Set<AnyCancellable>()
    private let repository: SharePreviewV2RepositoryProtocol
    
    // API response caching
    private var shareByUrlVO: SharebyURLVOData?
    private var shareLinkV2Data: ShareLinkV2Data?
    private var folderV2Data: FolderV2Data?

    // Navigation callbacks
    var onNavigateToFolder: ((NavigateMinParams) -> Void)?
    var onNavigateToSharedWithMe: ((NavigateMinParams?) -> Void)?
    var onNavigateToSharedByMe: (() -> Void)?

    // MARK: - Init
    init(shareToken: String,
         repository: SharePreviewV2RepositoryProtocol = SharePreviewV2Repository()) {
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
        displayMode = .loading
        do {
            // Step 1: Check share link (V1)
            shareByUrlVO = try await repository.checkShareLink(token: shareToken)
            
            // Step 2: Get V2 share link data
            shareLinkV2Data = try await repository.getShareLinkByToken(token: shareToken)
            
            // Update UI with basic info
            shareName = shareByUrlVO?.folderVO?.displayName ?? ""
            sharedByName = shareByUrlVO?.accountVO?.fullName ?? ""
            archiveName = shareByUrlVO?.archiveVO?.fullName ?? ""
            thumbnailURL = shareByUrlVO?.folderVO?.thumbURL200
            
            // Determine display mode
            displayMode = determineDisplayMode()
            
            // Step 3 & 4: If we have access, fetch folder content
            if displayMode == .fullAccess || displayMode == .fullAccessAuthor {
                try await loadFolderContent()
            }
            
            isLoading = false
        } catch {
            isLoading = false
            displayMode = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadFolderContent() async throws {
        guard let folderId = shareLinkV2Data?.itemId else { return }
        
        // Get folder metadata
        folderV2Data = try await repository.getFolderById(
            folderId: folderId,
            shareToken: shareToken
        )
        
        // Get folder children
        let folderChildren = try await repository.getFolderChildren(
            folderId: folderId,
            shareToken: shareToken,
            pageSize: 99999999
        )
        
        // Update UI items
        items = folderChildren.map { child in
            SharePreviewItem(
                id: child.itemId ?? UUID().uuidString,
                name: child.displayName ?? "",
                thumbnailURL: child.bestThumbnailURL,
                isFolder: child.isFolder,
                type: child.isFolder ? .folder : .other,
                placeholderImageName: nil
            )
        }
    }
    
    private func determineDisplayMode() -> SharePreviewDisplayMode {
        // Author always has full access, navigates to Shared By Me
        if isAuthor {
            return .fullAccessAuthor
        }
        
        // Unrestricted shares always show real content
        if shareLinkV2Data?.accessRestrictions == "none" {
            return .fullAccess
        }
        
        // Restricted shares - check ShareVO status
        guard let shareVO = shareByUrlVO?.shareVO else {
            return .requestAccess
        }
        
        let status = ShareStatus.status(forValue: shareVO.status)
        switch status {
        case .accepted:
            return .fullAccess
        case .pending:
            return .pendingApproval
        default:
            return .requestAccess
        }
    }
    
    var isAuthor: Bool {
        guard let byArchiveId = shareByUrlVO?.byArchiveId,
              let currentArchiveId = currentArchive?.archiveId else {
            return false
        }
        return byArchiveId == currentArchiveId
    }
    
    func navigate() {
        Task {
            if isAuthor {
                onNavigateToSharedByMe?()
                return
            }
            
            // Call requestShareAccess to add share to account
            do {
                guard let archiveId = currentArchive?.archiveId else { return }
                _ = try await repository.requestShareAccess(
                    token: shareToken,
                    archiveId: archiveId
                )
                
                // Navigate based on item type
                if shareLinkV2Data?.itemType == "folder",
                   let folderLinkId = Int(folderV2Data?.folderLinkId ?? ""),
                   let archiveNo = shareByUrlVO?.folderVO?.archiveNbr {
                    let params = NavigateMinParams(
                        archiveNo: archiveNo,
                        folderLinkId: folderLinkId,
                        folderName: folderV2Data?.displayName
                    )
                    onNavigateToSharedWithMe?(params)
                } else {
                    onNavigateToSharedWithMe?(nil)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func parseShareData(_ data: SharePreviewData) {
        shareName = data.shareName
        sharedByName = data.sharedByName
        archiveName = data.archiveName
        thumbnailURL = data.thumbnailURL
        shareStatus = data.status

        items = data.items.map { SharePreviewItem(id: $0.id, name: $0.name, thumbnailURL: $0.thumbnailURL, isFolder: $0.isFolder, type: $0.type, placeholderImageName: nil) }
    }
}

// MARK: - Display Mode

enum SharePreviewDisplayMode: Equatable {
    case loading
    case fullAccess
    case fullAccessAuthor
    case requestAccess
    case pendingApproval
    case error(String)
    
    static func == (lhs: SharePreviewDisplayMode, rhs: SharePreviewDisplayMode) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading),
             (.fullAccess, .fullAccess),
             (.fullAccessAuthor, .fullAccessAuthor),
             (.requestAccess, .requestAccess),
             (.pendingApproval, .pendingApproval):
            return true
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

// MARK: - Supporting Protocols & Mocks

// Repository protocol and a lightweight mock implementation are declared here.
// Shared model types live in `SharePreviewModels.swift`.

protocol SharePreviewV2RepositoryProtocol {
    func checkShareLink(token: String) async throws -> SharebyURLVOData
    func getShareLinkByToken(token: String) async throws -> ShareLinkV2Data
    func getFolderById(folderId: String, shareToken: String) async throws -> FolderV2Data
    func getFolderChildren(folderId: String, shareToken: String, pageSize: Int) async throws -> [FolderChildV2Data]
    func requestShareAccess(token: String, archiveId: Int) async throws -> ShareVOData
}

struct SharePreviewV2Repository: SharePreviewV2RepositoryProtocol {
    
    func checkShareLink(token: String) async throws -> SharebyURLVOData {
        return try await withCheckedThrowingContinuation { continuation in
            let operation = APIOperation(ShareEndpoint.checkLink(token: token))
            operation.execute(in: APIRequestDispatcher()) { result in
                switch result {
                case .json(let response, _):
                    guard let model: APIResults<SharebyURLVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<SharebyURLVO>.decoder
                    ), model.isSuccessful,
                    let data = model.results.first?.data?.first?.shareByURLVO else {
                        continuation.resume(throwing: APIError.unknown)
                        return
                    }
                    continuation.resume(returning: data)
                case .error(let error, _):
                    continuation.resume(throwing: error)
                default:
                    continuation.resume(throwing: APIError.unknown)
                }
            }
        }
    }
    
    func getShareLinkByToken(token: String) async throws -> ShareLinkV2Data {
        return try await withCheckedThrowingContinuation { continuation in
            let operation = APIOperation(ShareLinksV2Endpoint.getShareLinkByToken(token: token))
            operation.execute(in: APIRequestDispatcher()) { result in
                switch result {
                case .json(let response, _):
                    guard let model: ShareLinkV2Response = JSONHelper.decoding(
                        from: response,
                        with: ShareLinkV2Response.decoder
                    ), let data = model.items?.first else {
                        continuation.resume(throwing: APIError.unknown)
                        return
                    }
                    continuation.resume(returning: data)
                case .error(let error, _):
                    continuation.resume(throwing: error)
                default:
                    continuation.resume(throwing: APIError.unknown)
                }
            }
        }
    }
    
    func getFolderById(folderId: String, shareToken: String) async throws -> FolderV2Data {
        return try await withCheckedThrowingContinuation { continuation in
            let operation = APIOperation(FolderV2Endpoint.getFolderById(
                folderId: folderId,
                shareToken: shareToken
            ))
            operation.execute(in: APIRequestDispatcher()) { result in
                switch result {
                case .json(let response, _):
                    guard let model: FolderV2Response = JSONHelper.decoding(
                        from: response,
                        with: FolderV2Response.decoder
                    ), let data = model.items?.first else {
                        continuation.resume(throwing: APIError.unknown)
                        return
                    }
                    continuation.resume(returning: data)
                case .error(let error, _):
                    continuation.resume(throwing: error)
                default:
                    continuation.resume(throwing: APIError.unknown)
                }
            }
        }
    }
    
    func getFolderChildren(folderId: String, shareToken: String, pageSize: Int) async throws -> [FolderChildV2Data] {
        return try await withCheckedThrowingContinuation { continuation in
            let operation = APIOperation(FolderV2Endpoint.getFolderChildren(
                folderId: folderId,
                shareToken: shareToken,
                pageSize: pageSize
            ))
            operation.execute(in: APIRequestDispatcher()) { result in
                switch result {
                case .json(let response, _):
                    guard let model: FolderChildrenV2Response = JSONHelper.decoding(
                        from: response,
                        with: FolderChildrenV2Response.decoder
                    ) else {
                        continuation.resume(throwing: APIError.unknown)
                        return
                    }
                    continuation.resume(returning: model.items ?? [])
                case .error(let error, _):
                    continuation.resume(throwing: error)
                default:
                    continuation.resume(throwing: APIError.unknown)
                }
            }
        }
    }
    
    func requestShareAccess(token: String, archiveId: Int) async throws -> ShareVOData {
        return try await withCheckedThrowingContinuation { continuation in
            let operation = APIOperation(ShareEndpoint.requestShareAccess(token: token))
            operation.execute(in: APIRequestDispatcher()) { result in
                switch result {
                case .json(let response, _):
                    guard let model: APIResults<ShareVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<ShareVO>.decoder
                    ), model.isSuccessful,
                    let data = model.results.first?.data?.first?.shareVO else {
                        continuation.resume(throwing: APIError.unknown)
                        return
                    }
                    continuation.resume(returning: data)
                case .error(let error, _):
                    continuation.resume(throwing: error)
                default:
                    continuation.resume(throwing: APIError.unknown)
                }
            }
        }
    }
}
