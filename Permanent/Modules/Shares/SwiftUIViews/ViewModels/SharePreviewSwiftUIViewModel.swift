//
//  SharePreviewSwiftUIViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.01.2026
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SharePreviewSwiftUIViewModel: ObservableObject {
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
    @Published var shareStatus: ShareStatus = .needsApproval
    @Published var shareLinkV2Data: ShareLinkV2Data?

    // New flags & state for archive switching
    @Published var needsWorkspaceReload: Bool = false
    @Published var previousArchive: ArchiveVOData?
    @Published var originalArchiveNbr: String?
    @Published var cleanArchiveName: String?
    
    enum ContentDisplayMode {
        case actualThumbnails
        case blurredPlaceholders
    }
    
    // Sample placeholder items for blurred grid
    private static let placeholderItems: [SharePreviewItem] = [
        SharePreviewItem(id: "ph1", name: "Folder", thumbnailURL: nil, isFolder: true, type: .folder, placeholderImageName: "sharePreviewFolder"),
        SharePreviewItem(id: "ph2", name: "Photo", thumbnailURL: nil, isFolder: false, type: .image, placeholderImageName: "sharePreviewImageOne"),
        SharePreviewItem(id: "ph3", name: "Image", thumbnailURL: nil, isFolder: false, type: .image, placeholderImageName: "sharePreviewImageTwo"),
        SharePreviewItem(id: "ph4", name: "Picture", thumbnailURL: nil, isFolder: false, type: .image, placeholderImageName: "sharePreviewImageThree")
    ]

    // MARK: - Private
    private let shareToken: String
    private var cancellables = Set<AnyCancellable>()
    private let repository: SharePreviewRepositoryProtocol
    private let shareManagementRepository: ShareManagementRepository
    private var shareDataCache: SharebyURLVOData?
    private var loadTask: Task<Void, Never>?
    
    var displayMode: ContentDisplayMode {
        guard let v2Data = shareLinkV2Data else {
            // Default to actual thumbnails if V2 data not loaded yet
            return .actualThumbnails
        }
        
        let accessRestrictions = v2Data.accessRestrictions ?? "none"
        let previewToggle = shareDataCache?.previewToggle ?? 1
        let hasAccess = shareDataCache?.shareVO != nil
        
        // Unrestricted shares always show actual thumbnails
        if accessRestrictions == "none" {
            return .actualThumbnails
        }
        
        // Restricted shares: if preview is disabled, always show placeholders
        // (backend returns fake placeholder items when previewToggle=0)
        if previewToggle == 0 {
            return .blurredPlaceholders
        }
        
        // Restricted shares with preview enabled: show actual thumbnails
        return .actualThumbnails
    }

    // Navigation callbacks
    var onNavigateToFolder: ((NavigateMinParams) -> Void)?
    var onNavigateToShares: ((String) -> Void)?

    // MARK: - Init
    init(shareToken: String,
         repository: SharePreviewRepositoryProtocol = SharePreviewAPIService(),
         shareManagementRepository: ShareManagementRepository = ShareManagementRepository()) {
        self.shareToken = shareToken
        self.repository = repository
        self.shareManagementRepository = shareManagementRepository
        // Don't auto-select archive - let user choose
        self.currentArchive = nil
    }

    // MARK: - Public
    func start() {
        // Cancel previous task if any (ensures previous requests are cancelled when a new link is opened)
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self = self else { return }
            await self.loadShareData()
        }
        loadAvailableArchives()
    }

    func selectArchive(_ archive: ArchiveVOData) {
        // Immediate feedback: set currentArchive so UI updates instantly
        let didChange = archive.archiveNbr != currentArchive?.archiveNbr
        previousArchive = currentArchive
        currentArchive = archive
        errorMessage = nil
        isLoading = true

        AuthenticationManager.shared.changeArchive(archive) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }

                switch result {
                case .success(let changed):
                    if changed {
                        if didChange {
                            self.needsWorkspaceReload = true
                            // Post notification immediately after successful archive change
                            NotificationCenter.default.post(name: ArchivesViewModel.didChangeArchiveNotification, object: nil)
                        }
                        // Reload share data in the context of the newly selected archive
                        self.start()
                    } else {
                        self.errorMessage = "Failed to change archive"
                        self.currentArchive = self.previousArchive
                    }

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.currentArchive = self.previousArchive
                }

                self.isLoading = false
            }
        }
    }

    @Published var showArchiveMismatchAlert: Bool = false
    @Published var shouldOpenArchivePicker: Bool = false

    func viewInArchive() {
        let isShareCreator = checkIfUserIsCreator()
        
        if isShareCreator {
            // If creator, ensure they have selected the original archive where the share was created
            if let original = originalArchiveNbr, !original.isEmpty,
               let current = currentArchive?.archiveNbr,
               current != original {
                // Prompt user to change archive
                showArchiveMismatchAlert = true
                return
            }

            // For share creators, navigate to folder location using stored params
            if let callback = onNavigateToFolder,
               let archiveNbr = currentArchive?.archiveNbr,
               let folderLinkId = shareDataCache?.folderData?.folderLinkID {
                let folderName = shareDataCache?.folderData?.displayName ?? shareName
                callback((archiveNo: archiveNbr, folderLinkId: folderLinkId, folderName: folderName))
            }
        } else {
            // For non-creators, navigate to Shared With Me tab
            if let navigateToShares = onNavigateToShares,
               let archiveNbr = currentArchive?.archiveNbr {
                navigateToShares(archiveNbr)
            }
        }
    }
    
    private func checkIfUserIsCreator() -> Bool {
        guard let shareCreatorEmail = shareDataCache?.accountVO?.primaryEmail,
              let currentUserEmail = AuthenticationManager.shared.session?.account.primaryEmail else {
            return false
        }
        return shareCreatorEmail == currentUserEmail
    }
    
    private func loadV2ShareLinkData(shareLinkId: Int) {
        shareManagementRepository.getShareLinkV2(shareLinkId: "\(shareLinkId)") { [weak self] result, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let v2Data = result {
                    self.shareLinkV2Data = v2Data
                    // Re-extract files with updated display mode
                    if let cachedData = self.shareDataCache {
                        self.extractFiles(from: cachedData)
                    }
                }
                // V2 data is supplementary - don't show error to user
            }
        }
    }

    // MARK: - Private
    private func loadAvailableArchives() {
        // Fetch all archives - don't auto-select any
        AuthenticationManager.shared.getAccountArchives { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let archiveVOs):
                    // Convert ArchiveVO to ArchiveVOData and filter out placeholders (e.g., 'create new')
                    self.availableArchives = archiveVOs.compactMap { $0.archiveVO }
                        .filter { $0.status == .ok && $0.archiveNbr != nil && !($0.fullName?.isEmpty ?? true) }
                    // Don't auto-select - user must choose
                    
                case .failure(let error):
                    // If fetch fails, keep empty list
                    self.availableArchives = []
                }
            }
        }
    }

    private func buildShareDetailsFromState() throws -> ShareDetails {
        // Building ShareDetails is not supported in this simplified ViewModel - throw
        throw NSError(domain: "SharePreview", code: -1, userInfo: nil)
    }

    private func loadShareData() async {
        isLoading = true
        errorMessage = nil

        do {
            let shareByURL = try await repository.fetchSharePreview(shareToken: shareToken)
            await parseShareData(shareByURL)
            
            // Clean up stored token after successful load
            PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.shareURLToken)
        } catch is CancellationError {
            // User-initiated cancellation - silently ignore and ensure loading UI is cleared
            await MainActor.run {
                self.errorMessage = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    func cancelLoadingTask() {
        loadTask?.cancel()
        loadTask = nil
        Task { @MainActor in
            self.isLoading = false
            self.errorMessage = nil
        }
    }
    
    deinit {
        loadTask?.cancel()
    }

    private func parseShareData(_ shareByURL: SharebyURLVOData) async {
        // Cache for later use
        shareDataCache = shareByURL
        
        // Fetch V2 data for accessRestrictions
        if let sharebyURLID = shareByURL.sharebyURLID {
            loadV2ShareLinkData(shareLinkId: sharebyURLID)
        }
        
        // Parse archive info
        if let archive = shareByURL.archiveVO?.fullName {
            archiveName = archive
            // Store original archive metadata from share for validation if user is creator
            originalArchiveNbr = shareByURL.archiveVO?.archiveNbr
            cleanArchiveName = "The \(archive) Archive"
        }
        
        // Parse creator info
        if let name = shareByURL.accountVO?.fullName {
            sharedByName = name
        }
        
        // Parse archive thumbnail
        thumbnailURL = shareByURL.archiveVO?.thumbURL200
        
        // Parse shared item name
        shareName = shareByURL.recordData?.displayName ?? shareByURL.folderData?.displayName ?? ""
        
        // Check if user is the share creator
        _ = checkIfUserIsCreator(shareByURL: shareByURL)
        
        // Determine access status
        let hasAccess = shareByURL.shareVO != nil
        let autoApprove = shareByURL.autoApproveToggle == 1
        
        // Set initial status based on shareVO
        if let shareVO = shareByURL.shareVO {
            shareStatus = ShareStatus.status(forValue: shareVO.status)
        } else {
            shareStatus = .needsApproval
        }
        
        // Always extract files - displayMode will determine if we show placeholders or actual content
        extractFiles(from: shareByURL)
        
        // Auto-approve flow: if auto-approve is enabled and user doesn't have access, request it automatically
        if autoApprove && !hasAccess {
            await requestShareAccessAutomatically()
        }
    }
    
    private func checkIfUserIsCreator(shareByURL: SharebyURLVOData) -> Bool {
        guard let shareCreatorEmail = shareByURL.accountVO?.primaryEmail,
              let currentUserEmail = AuthenticationManager.shared.session?.account.primaryEmail else {
            return false
        }
        
        return shareCreatorEmail == currentUserEmail
    }
    
    private func extractFiles(from shareByURL: SharebyURLVOData) {
        // Check if we should show placeholders
        if displayMode == .blurredPlaceholders {
            items = Self.placeholderItems
            return
        }
        
        var extractedItems: [SharePreviewItem] = []
        
        // Extract from folder data (folder share)
        if let folderData = shareByURL.folderData,
           let children = folderData.childItemVOS {
            for (index, child) in children.enumerated() {
                // Use folderLinkID if available, otherwise use index to ensure unique IDs
                let uniqueID: String
                if let linkID = child.folderLinkID, linkID != 0 {
                    uniqueID = "\(linkID)"
                } else {
                    uniqueID = "item_\(index)"
                }
                
                let item = SharePreviewItem(
                    id: uniqueID,
                    name: child.displayName ?? "",
                    thumbnailURL: child.thumbURL500,
                    isFolder: child.type == "type.folder.root.public" || child.type == "type.folder.root.private" || child.type == "type.folder.root.app",
                    type: child.type == "type.folder.root.public" || child.type == "type.folder.root.private" ? .folder : .image
                )
                extractedItems.append(item)
            }
        }
        // Extract from record data (file share)
        else if let recordData = shareByURL.recordData {
            let item = SharePreviewItem(
                id: "\(recordData.recordID ?? 0)",
                name: recordData.displayName ?? "",
                thumbnailURL: recordData.thumbURL2000,
                isFolder: false,
                type: .image
            )
            extractedItems.append(item)
        }
        
        items = extractedItems
    }
    
    private func requestShareAccessAutomatically() async {
        do {
            let shareVO = try await repository.requestShareAccess(shareToken: shareToken)
            shareStatus = ShareStatus.status(forValue: shareVO.status)
        } catch {
            // Silent fail for auto-approve - don't show error to user
            // They can manually request access if needed
        }
    }
}

// MARK: - Model Types (shared with views)
struct SharePreviewItem: Identifiable {
    let id: String
    let name: String
    let thumbnailURL: String?
    let isFolder: Bool
    let type: SharePreviewItemType
    let placeholderImageName: String?
    
    init(id: String, name: String, thumbnailURL: String?, isFolder: Bool, type: SharePreviewItemType, placeholderImageName: String? = nil) {
        self.id = id
        self.name = name
        self.thumbnailURL = thumbnailURL
        self.isFolder = isFolder
        self.type = type
        self.placeholderImageName = placeholderImageName
    }
}

enum SharePreviewItemType: String, Codable {
    case folder = "folder"
    case image = "image"
    case other = "other"
}

// MARK: - Repository Protocol
protocol SharePreviewRepositoryProtocol {
    func fetchSharePreview(shareToken: String) async throws -> SharebyURLVOData
    func requestShareAccess(shareToken: String) async throws -> ShareVOData
}

// MARK: - Production API Service
struct SharePreviewAPIService: SharePreviewRepositoryProtocol {
    func fetchSharePreview(shareToken: String) async throws -> SharebyURLVOData {
        var apiOperation: APIOperation?
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                let operation = APIOperation(ShareEndpoint.checkLink(token: shareToken))
                apiOperation = operation
                operation.execute(in: APIRequestDispatcher()) { result in
                    switch result {
                    case .json(let response, _):
                        guard let model: APIResults<SharebyURLVO> = JSONHelper.decoding(
                            from: response,
                            with: APIResults<SharebyURLVO>.decoder
                        ),
                              model.isSuccessful,
                              let shareByURL = model.results.first?.data?.first?.shareByURLVO else {
                            continuation.resume(throwing: NSError(domain: "SharePreview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to load share"]))
                            return
                        }
                        continuation.resume(returning: shareByURL)
                        
                    case .error(let error, _):
                        // Map cancellation to CancellationError to allow Task cancellation propagation
                        if let nsErr = error as NSError?, nsErr.code == NSURLErrorCancelled {
                            continuation.resume(throwing: CancellationError())
                        } else {
                            continuation.resume(throwing: error ?? NSError(domain: "SharePreview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                        }
                        
                    default:
                        continuation.resume(throwing: NSError(domain: "SharePreview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
                    }
                }
            }
        }, onCancel: {
            apiOperation?.cancel()
        })
    }
    
    func requestShareAccess(shareToken: String) async throws -> ShareVOData {
        var apiOperation: APIOperation?
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                let operation = APIOperation(ShareEndpoint.requestShareAccess(token: shareToken))
                apiOperation = operation
                operation.execute(in: APIRequestDispatcher()) { result in
                    switch result {
                    case .json(let response, _):
                        guard let model: APIResults<ShareVO> = JSONHelper.decoding(
                            from: response,
                            with: APIResults<ShareVO>.decoder
                        ),
                              model.isSuccessful,
                              let shareVO = model.results.first?.data?.first?.shareVO else {
                            continuation.resume(throwing: NSError(domain: "SharePreview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to request access"]))
                            return
                        }
                        continuation.resume(returning: shareVO)
                        
                    case .error(let error, _):
                        if let nsErr = error as NSError?, nsErr.code == NSURLErrorCancelled {
                            continuation.resume(throwing: CancellationError())
                        } else {
                            continuation.resume(throwing: error ?? NSError(domain: "SharePreview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                        }
                        
                    default:
                        continuation.resume(throwing: NSError(domain: "SharePreview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
                    }
                }
            }
        }, onCancel: {
            apiOperation?.cancel()
        })
    }
}

// MARK: - Mock Repository (for tests)
struct SharePreviewMockRepository: SharePreviewRepositoryProtocol {
    func fetchSharePreview(shareToken: String) async throws -> SharebyURLVOData {
        // Return mock SharebyURLVOData for testing
        return createMockSharebyURLVOData()
    }
    
    func requestShareAccess(shareToken: String) async throws -> ShareVOData {
        // Return mock ShareVOData for testing
        return createMockShareVOData()
    }
    
    private func createMockSharebyURLVOData() -> SharebyURLVOData {
        let accountVO = AccountVOData(
            accountID: 1000, primaryEmail: "robert.friedman@example.com", fullName: "Robert Friedman",
            address: nil, address2: nil, country: nil, city: nil, state: nil, zip: nil,
            primaryPhone: nil, level: nil, apiToken: nil, betaParticipant: nil,
            facebookAccountID: nil, googleAccountID: nil, status: nil, type: nil,
            emailStatus: nil, phoneStatus: nil, notificationPreferences: nil,
            agreed: nil, optIn: nil, emailArray: nil, inviteCode: nil,
            rememberMe: nil, keepLoggedIn: nil, accessRole: nil, spaceTotal: nil,
            spaceLeft: nil, fileTotal: nil, fileLeft: nil, changePrimaryEmail: nil,
            changePrimaryPhone: nil, createdDT: nil, updatedDT: nil, hideChecklist: nil
        )
        
        let archiveVO = ArchiveVOData(
            childFolderVOS: nil, folderSizeVOS: nil, recordVOS: nil,
            accessRole: "access.role.owner", fullName: "Family", spaceTotal: nil,
            spaceLeft: nil, fileTotal: nil, fileLeft: nil, relationType: nil,
            homeCity: nil, homeState: nil, homeCountry: nil, itemVOS: nil,
            birthDay: nil, company: nil, archiveVODescription: nil, archiveID: 1850,
            publicDT: nil, archiveNbr: "0001-0000", view: nil, viewProperty: nil,
            archiveVOPublic: nil, vaultKey: nil, thumbArchiveNbr: nil, type: nil,
            thumbStatus: nil, imageRatio: nil, thumbURL200: nil, thumbURL500: nil,
            thumbURL1000: nil, thumbURL2000: nil, thumbDT: nil, createdDT: nil,
            updatedDT: nil, status: .ok
        )
        
        let shareVO = ShareVOData(
            shareID: 1, folderLinkID: 100, archiveID: 1850,
            accessRole: "access.role.viewer", type: nil,
            status: "status.generic.ok", requestToken: nil, previewToggle: nil,
            folderVO: nil, recordVO: nil, archiveVO: nil, accountVO: nil,
            createdDT: nil, updatedDT: nil
        )
        
        return SharebyURLVOData(
            sharebyURLID: 919, status: "status.generic.ok", urlToken: "mock-token",
            folderLinkID: nil, shareURL: nil, uses: 3, maxUses: 0,
            autoApproveToggle: 1, previewToggle: 1, defaultAccessRole: "access.role.viewer",
            expiresDT: nil, byAccountID: 1000, byArchiveID: 1850, createdDT: nil,
            updatedDT: nil, accountVO: accountVO, folderData: nil, recordData: nil,
            archiveVO: archiveVO, shareVO: shareVO
        )
    }
    
    private func createMockShareVOData() -> ShareVOData {
        return ShareVOData(
            shareID: 1, folderLinkID: 100, archiveID: 1850,
            accessRole: "access.role.viewer", type: nil,
            status: "status.generic.ok", requestToken: nil, previewToggle: nil,
            folderVO: nil, recordVO: nil, archiveVO: nil, accountVO: nil,
            createdDT: nil, updatedDT: nil
        )
    }
}

