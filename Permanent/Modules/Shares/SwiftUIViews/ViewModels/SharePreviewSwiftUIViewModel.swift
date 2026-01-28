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
    @Published var needsWorkspaceReload: Bool = false
    @Published var previousArchive: ArchiveVOData?
    @Published var originalArchiveNbr: String?
    @Published var cleanArchiveName: String?
    
    private var initialArchive: ArchiveVOData?
    private var archiveBeforePreview: ArchiveVOData?
    
    enum ContentDisplayMode {
        case actualThumbnails
        case blurredPlaceholders
    }
    
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
    private var hasLoadedRealThumbnails: Bool = false
    
    private func shouldShowActualThumbnails() -> Bool {
        let isCreator = checkIfUserIsCreator()
        if isCreator {
            return true
        }
        
        guard let v2Data = shareLinkV2Data else {
            return false
        }
        
        let accessRestrictions = v2Data.accessRestrictions ?? "none"
        let previewToggle = shareDataCache?.previewToggle ?? 1
        
        if accessRestrictions == "none" {
            return true
        }
        
        // Check if current archive has approved access
        if let shareVO = shareDataCache?.shareVO,
           let currentArchiveId = currentArchive?.archiveID,
           shareVO.archiveID == currentArchiveId,
           let status = shareVO.status?.lowercased(),
           status.contains("ok") {
            // Archive has approved access - always show real thumbnails regardless of previewToggle
            return true
        }
        
        // Archive doesn't have access - check previewToggle to decide if preview is allowed
        if previewToggle == 0 {
            return false
        }

        
        // Archive doesn't have access and preview is disabled
        if previewToggle == 0 {
            return false
        }
        
        return false
    }
    
    var displayMode: ContentDisplayMode {
        if !hasLoadedRealThumbnails {
            return .blurredPlaceholders
        }
        return shouldShowActualThumbnails() ? .actualThumbnails : .blurredPlaceholders
    }

    var onNavigateToFolder: ((NavigateMinParams) -> Void)?
    var onNavigateToShares: ((String) -> Void)?
    var onNavigateToSharedWithMe: ((NavigateMinParams?) -> Void)?
    var onNavigateToSharedByMe: (() -> Void)?

    init(shareToken: String,
         repository: SharePreviewRepositoryProtocol = SharePreviewAPIService(),
         shareManagementRepository: ShareManagementRepository = ShareManagementRepository()) {
        self.shareToken = shareToken
        self.repository = repository
        self.shareManagementRepository = shareManagementRepository
        self.currentArchive = nil
    }

    // MARK: - Public
    func start() {
        // Capture the archive user had before entering share preview
        if archiveBeforePreview == nil {
            archiveBeforePreview = AuthenticationManager.shared.session?.selectedArchive
        }
        
        // For unrestricted (public) shares, keep thumbnails visible during archive switches
        let isUnrestricted = (shareLinkV2Data?.accessRestrictions ?? "none") == "none"
        if !isUnrestricted {
            hasLoadedRealThumbnails = false
        }
        
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self = self else { return }
            await self.loadShareData()
        }
        loadAvailableArchives()
    }

    func selectArchive(_ archive: ArchiveVOData) {
        guard archive.archiveNbr != currentArchive?.archiveNbr else {
            return
        }
        
        let didChange = true
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
                        self.needsWorkspaceReload = true
                        NotificationCenter.default.post(name: ArchivesViewModel.didChangeArchiveNotification, object: nil)
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
    
    enum ShareButtonState {
        case open
        case requestAccess
        case accessRequested
    }
    
    var buttonState: ShareButtonState {
        let isCreator = checkIfUserIsCreator()
        
        if isCreator {
            return .open
        }
        
        let isUnrestricted = (shareLinkV2Data?.accessRestrictions ?? "none") == "none"
        if isUnrestricted {
            return .open
        }
        
        if let shareVO = shareDataCache?.shareVO,
           let currentArchiveId = currentArchive?.archiveID,
           shareVO.archiveID == currentArchiveId {
            let status = shareVO.status ?? ""
            if status.contains("pending") {
                return .accessRequested
            } else if status.contains("ok") {
                return .open
            }
        }
        
        return .requestAccess
    }
    
    var buttonTitle: String {
        switch buttonState {
        case .open:
            return "Open"
        case .requestAccess:
            return "Request Access"
        case .accessRequested:
            return "Access Requested"
        }
    }
    
    var isButtonDisabled: Bool {
        return buttonState == .accessRequested
    }

    func viewInArchive() {
        let currentButtonState = buttonState
        
        switch currentButtonState {
        case .open:
            handleOpenAction()
            
        case .requestAccess:
            handleRequestAccessAction()
            
        case .accessRequested:
            break
        }
    }
    
    private func handleOpenAction() {
        let isShareCreator = checkIfUserIsCreator()
        
        if isShareCreator {
            onNavigateToSharedByMe?()
        } else {
            // Add share to account before navigating
            isLoading = true
            errorMessage = nil
            
            Task { @MainActor in
                do {
                    _ = try await repository.requestShareAccess(shareToken: shareToken)
                    self.isLoading = false
                    self.navigateToFolder()
                } catch let error as NSError where error.code == 409 {
                    // Share already added to account
                    self.isLoading = false
                    self.navigateToFolder()
                } catch {
                    self.errorMessage = "Unable to open share. Please try again."
                    self.isLoading = false
                }
            }
        }
    }
    
    private func handleRequestAccessAction() {
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                let shareData = try await repository.requestShareAccess(shareToken: shareToken)
                await loadShareData()
                
            } catch let error as NSError where error.code == 409 {
                await loadShareData()
            } catch {
                errorMessage = "Unable to request access. Please try again."
                isLoading = false
            }
        }
    }
    
    private func navigateToFolder() {
        if let folderData = self.shareDataCache?.folderData,
           let folderLinkId = folderData.folderLinkID,
           let archiveNbr = self.currentArchive?.archiveNbr {
            let params: NavigateMinParams = (archiveNo: archiveNbr, folderLinkId: folderLinkId, folderName: folderData.displayName)
            self.onNavigateToSharedWithMe?(params)
        } else if let navigateToShares = self.onNavigateToShares,
                  let archiveNbr = self.currentArchive?.archiveNbr {
            navigateToShares(archiveNbr)
        }
    }
    
    private func checkIfUserIsCreator() -> Bool {
        guard let shareCreatorAccountId = shareDataCache?.byAccountID,
              let shareCreatorArchiveId = shareDataCache?.byArchiveID,
              let currentUserAccountId = AuthenticationManager.shared.session?.account.accountID,
              let currentArchiveId = currentArchive?.archiveID else {
            return false
        }
        
        let isCreator = shareCreatorAccountId == currentUserAccountId && shareCreatorArchiveId == currentArchiveId
        return isCreator
    }
    
    private func loadV2ShareLinkData(shareLinkId: Int) {
        shareManagementRepository.getShareLinkV2(shareLinkId: "\(shareLinkId)") { [weak self] result, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let v2Data = result {
                    self.shareLinkV2Data = v2Data
                    
                    let accessRestrictions = v2Data.accessRestrictions ?? "none"
                    let isCreator = self.checkIfUserIsCreator()
                    
                    if (isCreator || accessRestrictions == "none" || self.shouldShowActualThumbnails()) {
                        await self.loadV2FolderContent()
                    } else {
                        if let cachedData = self.shareDataCache {
                            self.extractFiles(from: cachedData)
                        }
                    }
                } else {
                    if let cachedData = self.shareDataCache {
                        self.extractFiles(from: cachedData)
                    }
                }
                self.isLoading = false
            }
        }
    }
    
    private func loadV2FolderContent() async {
        guard let folderId = shareDataCache?.folderData?.folderID,
              let _ = shareLinkV2Data else {
            return
        }
        
        do {
            let children = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[FolderChildV2Data], Error>) in
                let operation = APIOperation(FolderV2Endpoint.getFolderChildren(
                    folderId: "\(folderId)",
                    shareToken: shareToken,
                    pageSize: 99999999
                ))
                operation.execute(in: APIRequestDispatcher()) { result in
                    switch result {
                    case .json(let response, _):
                        guard let model: FolderChildrenV2Response = JSONHelper.decoding(
                            from: response,
                            with: FolderChildrenV2Response.decoder
                        ) else {
                            continuation.resume(throwing: NSError(domain: "SharePreview", code: -1, userInfo: nil))
                            return
                        }
                        continuation.resume(returning: model.items ?? [])
                    case .error(let error, _):
                        continuation.resume(throwing: error ?? NSError(domain: "SharePreview", code: -1, userInfo: nil))
                    default:
                        continuation.resume(throwing: NSError(domain: "SharePreview", code: -1, userInfo: nil))
                    }
                }
            }
            
            var extractedItems: [SharePreviewItem] = []
            for (index, child) in children.enumerated() {
                let uniqueID = child.itemId ?? "item_\(index)"
                let item = SharePreviewItem(
                    id: uniqueID,
                    name: child.displayName ?? "",
                    thumbnailURL: child.bestThumbnailURL,
                    isFolder: child.isFolder,
                    type: child.isFolder ? .folder : .image
                )
                extractedItems.append(item)
            }
            
            items = extractedItems
            hasLoadedRealThumbnails = true
            
        } catch {
            if let cachedData = shareDataCache {
                extractFiles(from: cachedData)
            }
        }
    }

    // MARK: - Private
    private func loadAvailableArchives() {
        AuthenticationManager.shared.getAccountArchives { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let archiveVOs):
                    self.availableArchives = archiveVOs.compactMap { $0.archiveVO }
                        .filter { $0.status == .ok && $0.archiveNbr != nil && !($0.fullName?.isEmpty ?? true) }
                    
                case .failure:
                    self.availableArchives = []
                }
            }
        }
    }

    func buildShareDetailsFromState() throws -> ShareDetails {
        throw NSError(domain: "SharePreview", code: -1, userInfo: nil)
    }

    private func loadShareData() async {
        isLoading = true
        errorMessage = nil

        do {
            let shareByURL = try await repository.fetchSharePreview(shareToken: shareToken)
            await parseShareData(shareByURL)
            
            PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.shareURLToken)
        } catch is CancellationError {
            await MainActor.run {
                self.errorMessage = nil
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func cancelLoadingTask() {
        loadTask?.cancel()
        loadTask = nil
        Task { @MainActor in
            self.isLoading = false
            self.errorMessage = nil
        }
    }
    
    func restoreInitialArchive(completion: @escaping () -> Void) {
        guard let archiveToRestore = archiveBeforePreview,
              let current = currentArchive,
              archiveToRestore.archiveNbr != current.archiveNbr else {
            completion()
            return
        }
        
        isLoading = true
        
        AuthenticationManager.shared.changeArchive(archiveToRestore) { [weak self] result in
            Task { @MainActor in
                guard let self = self else { 
                    completion()
                    return 
                }
                
                switch result {
                case .success(let changed):
                    if changed {
                        NotificationCenter.default.post(name: ArchivesViewModel.didChangeArchiveNotification, object: nil)
                    }
                    
                    // Wait for workspace to reload before dismissing to avoid showing loading state in background
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.isLoading = false
                        completion()
                    }
                    
                case .failure:
                    self.isLoading = false
                    completion()
                }
            }
        }
    }
    
    deinit {
        loadTask?.cancel()
    }

    private func parseShareData(_ shareByURL: SharebyURLVOData) async {
        shareDataCache = shareByURL
        
        if let sharebyURLID = shareByURL.sharebyURLID {
            loadV2ShareLinkData(shareLinkId: sharebyURLID)
        }
        
        if let archive = shareByURL.archiveVO?.fullName {
            archiveName = archive
            originalArchiveNbr = shareByURL.archiveVO?.archiveNbr
            cleanArchiveName = "The \(archive) Archive"
        }
        
        if let name = shareByURL.accountVO?.fullName {
            sharedByName = name
        }
        
        thumbnailURL = shareByURL.archiveVO?.thumbURL200
        shareName = shareByURL.recordData?.displayName ?? shareByURL.folderData?.displayName ?? ""
        
        _ = checkIfUserIsCreator(shareByURL: shareByURL)
        
        if let shareVO = shareByURL.shareVO {
            shareStatus = ShareStatus.status(forValue: shareVO.status)
        } else {
            shareStatus = .needsApproval
        }
    }
    
    private func checkIfUserIsCreator(shareByURL: SharebyURLVOData) -> Bool {
        guard let shareCreatorAccountId = shareByURL.byAccountID,
              let shareCreatorArchiveId = shareByURL.byArchiveID,
              let currentUserAccountId = AuthenticationManager.shared.session?.account.accountID,
              let currentArchiveId = currentArchive?.archiveID else {
            return false
        }
        return shareCreatorAccountId == currentUserAccountId && shareCreatorArchiveId == currentArchiveId
    }
    
    private func extractFiles(from shareByURL: SharebyURLVOData) {
        if !shouldShowActualThumbnails() {
            items = Self.placeholderItems
            return
        }
        
        var extractedItems: [SharePreviewItem] = []
        
        if let folderData = shareByURL.folderData,
           let children = folderData.childItemVOS {
            for (index, child) in children.enumerated() {
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
        hasLoadedRealThumbnails = true
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
                        ) else {
                            continuation.resume(throwing: NSError(domain: "SharePreview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to request access"]))
                            return
                        }
                        
                        if let firstResult = model.results.first,
                           let message = firstResult.message.first,
                           message.contains("already_exists") {
                            continuation.resume(throwing: NSError(domain: "SharePreview", code: 409, userInfo: [NSLocalizedDescriptionKey: "Share already exists"]))
                            return
                        }
                        
                        guard model.isSuccessful,
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

