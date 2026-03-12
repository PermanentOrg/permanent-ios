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
    @Published var displayedArchive: ArchiveVOData?  // Archive shown in UI
    @Published var availableArchives: [ArchiveVOData] = []
    @Published var shareStatus: ShareStatus = .needsApproval
    @Published var shareLinkV2Data: ShareLinkV2Data?
    @Published var needsWorkspaceReload: Bool = false
    @Published var previousArchive: ArchiveVOData?
    @Published var originalArchiveNbr: String?
    @Published var cleanArchiveName: String?
    @Published var hasCompletedInitialLoad: Bool = false
    @Published var showCreateArchiveSheet: Bool = false
    @Published var showArchiveTypeSelection: Bool = false
    @Published var newArchiveName: String = ""
    @Published var selectedArchiveType: ArchiveType = .person
    @Published var isCreatingArchive: Bool = false
    
    private var initialArchive: ArchiveVOData?
    private var archiveBeforePreview: ArchiveVOData?
    private var pendingArchive: ArchiveVOData?  // Archive being switched to during loading
    
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
    private let createArchiveCoordinator = SharePreviewCreateArchiveCoordinator()
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
        
        // Check if current archive has approved access.
        if let shareVO = shareDataCache?.shareVO,
           let currentArchiveId = currentArchive?.archiveID,
           shareVO.archiveID == currentArchiveId,
           let status = shareVO.status?.lowercased(),
           status.contains("ok") {
            return true
        }

        // Restricted share + no approved access: respect preview toggle.
        return previewToggle != 0
    }
    
    var displayMode: ContentDisplayMode {
        if !hasLoadedRealThumbnails {
            return .blurredPlaceholders
        }
        return shouldShowActualThumbnails() ? .actualThumbnails : .blurredPlaceholders
    }

    var selectableArchives: [ArchiveVOData] {
        availableArchives.filter { archive in
            archive.archiveNbr != nil && !(archive.fullName?.isEmpty ?? true)
        }
    }

    var onNavigateToFolder: ((NavigateMinParams) -> Void)?
    var onNavigateToShares: ((String) -> Void)?
    var onNavigateToSharedWithMe: ((NavigateMinParams?) -> Void)?
    var onNavigateToSharedByMe: ((NavigateMinParams?) -> Void)?
    var onNavigateToFilePreview: ((FilePreviewParams) -> Void)?

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
        
        previousArchive = currentArchive
        currentArchive = archive  // Update immediately for business logic
        pendingArchive = archive  // Store for UI update after parsing
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
                        // Don't set isLoading = false here, let loadShareData() handle it
                    } else {
                        self.errorMessage = "Failed to change archive"
                        self.currentArchive = self.previousArchive
                        self.pendingArchive = nil
                        self.isLoading = false
                    }

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.currentArchive = self.previousArchive
                    self.pendingArchive = nil
                    self.isLoading = false
                }
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
    
    @Published private(set) var currentButtonState: ShareButtonState = .requestAccess
    
    private var computedButtonState: ShareButtonState {
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
    
    var buttonState: ShareButtonState {
        return currentButtonState
    }
    
    var buttonTitle: String {
        switch currentButtonState {
        case .open:
            return "Open"
        case .requestAccess:
            return "Request Access"
        case .accessRequested:
            return "Access Requested"
        }
    }
    
    var isButtonDisabled: Bool {
        return currentButtonState == .accessRequested
    }
    
    var isOriginalArchiveSelected: Bool {
        guard let originalNbr = originalArchiveNbr,
              let currentNbr = displayedArchive?.archiveNbr else {
            return false
        }
        return originalNbr == currentNbr
    }

    var accessRoleText: String? {
        guard let shareDataCache = shareDataCache,
              currentArchive != nil else {
            return nil
        }

        if checkIfUserIsCreator() {
            return nil
        }

        let isUnrestricted = (shareLinkV2Data?.accessRestrictions ?? "none") == "none"

        if shareStatus == .pending {
            return nil
        }

        if !isUnrestricted && shareStatus != .accepted {
            return nil
        }

        var rawRole: String?
        if let shareVO = shareDataCache.shareVO,
           let currentArchiveId = currentArchive?.archiveID,
           shareVO.archiveID == currentArchiveId {
            rawRole = shareVO.accessRole
        } else if isUnrestricted {
            rawRole = shareDataCache.defaultAccessRole
        }

        guard let rawRole = rawRole else {
            return nil
        }

        let role = AccessRole.roleForValue(rawRole)
        if role == .owner {
            return nil
        }

        return role.title.uppercased()
    }

    func viewInArchive() {
        let currentState = currentButtonState
        
        switch currentState {
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
            // For creators, navigate to the folder in Shared by Me section
            if let folderData = shareDataCache?.folderData,
               let folderLinkId = folderData.folderLinkID,
               let archiveNbr = currentArchive?.archiveNbr {
                let params: NavigateMinParams = (archiveNo: archiveNbr, folderLinkId: folderLinkId, folderName: folderData.displayName)
                onNavigateToSharedByMe?(params)
            } else {
                // For non-folder shares or when folder data is missing, go to shared by me
                onNavigateToSharedByMe?(nil)
            }
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
                _ = try await repository.requestShareAccess(shareToken: shareToken)
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
        // Check if it's a single file/record - open in file preview directly
        if let recordData = self.shareDataCache?.recordData,
           let recordId = recordData.recordID,
           let folderLinkId = recordData.folderLinkID,
           let archiveNbr = self.currentArchive?.archiveNbr {
            let fileType = recordData.type ?? FileType.miscellaneous.rawValue
            let fileName = recordData.displayName ?? "File"
            let thumbnailURL = recordData.thumbURL2000 ?? recordData.thumbURL500 ?? ""
            let params = FilePreviewParams(
                name: fileName,
                recordId: recordId,
                folderLinkId: folderLinkId,
                archiveNbr: archiveNbr,
                type: fileType,
                thumbnailURL: thumbnailURL
            )
            self.onNavigateToFilePreview?(params)
        }
        // For folders, navigate to shared with me folder view
        else if let folderData = self.shareDataCache?.folderData,
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
    
    private func loadV2ShareLinkData() async {
        let v2Data = await fetchShareLinkV2ByToken()

        if let v2Data {
            shareLinkV2Data = v2Data

            let accessRestrictions = v2Data.accessRestrictions ?? "none"
            let isCreator = checkIfUserIsCreator()

            if isCreator || accessRestrictions == "none" || shouldShowActualThumbnails() {
                // Check if it's a folder or record share.
                if shareDataCache?.folderData != nil {
                    await loadV2FolderContent()
                } else if shareDataCache?.recordData != nil, let cachedData = shareDataCache {
                    // For record shares, just extract the record data.
                    extractFiles(from: cachedData)
                }
            } else if let cachedData = shareDataCache {
                extractFiles(from: cachedData)
            }
        } else if let cachedData = shareDataCache {
            extractFiles(from: cachedData)
        }

        isLoading = false
    }

    private func fetchShareLinkV2ByToken() async -> ShareLinkV2Data? {
        await withCheckedContinuation { continuation in
            shareManagementRepository.getShareLinkV2ByToken(token: shareToken) { result, _ in
                continuation.resume(returning: result)
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
    private func loadAvailableArchives(afterReload: (([ArchiveVOData]) -> Void)? = nil) {
        AuthenticationManager.shared.getAccountArchives { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let archiveVOs):
                    let archives = self.filterSelectableArchives(archiveVOs.compactMap { $0.archiveVO })
                    self.availableArchives = archives
                    self.syncArchiveReferences(with: archives)
                    afterReload?(archives)
                    
                case .failure:
                    self.availableArchives = []
                    afterReload?([])
                }
            }
        }
    }

    private func syncArchiveReferences(with archives: [ArchiveVOData]) {
        if let pendingId = pendingArchive?.archiveID,
           let refreshedPending = archives.first(where: { $0.archiveID == pendingId }) {
            pendingArchive = refreshedPending
        }

        if let currentId = currentArchive?.archiveID,
           let refreshedCurrent = archives.first(where: { $0.archiveID == currentId }) {
            currentArchive = refreshedCurrent
        }

        if let displayedId = displayedArchive?.archiveID,
           let refreshedDisplayed = archives.first(where: { $0.archiveID == displayedId }) {
            displayedArchive = refreshedDisplayed
        }
    }

    private func fetchAccountArchives() async -> [ArchiveVOData] {
        await withCheckedContinuation { continuation in
            AuthenticationManager.shared.getAccountArchives { result in
                Task { @MainActor in
                    switch result {
                    case .success(let archiveVOs):
                        let archives = self.filterSelectableArchives(archiveVOs.compactMap { $0.archiveVO })
                        continuation.resume(returning: archives)
                    case .failure:
                        continuation.resume(returning: [])
                    }
                }
            }
        }
    }

    private func filterSelectableArchives(_ archives: [ArchiveVOData]) -> [ArchiveVOData] {
        archives.filter { archive in
            archive.status == .ok &&
            archive.archiveNbr != nil &&
            !(archive.fullName?.isEmpty ?? true)
        }
    }

    private func archiveHasUsableThumbnail(_ archive: ArchiveVOData) -> Bool {
        guard let thumbURL = archive.thumbURL200, !thumbURL.isEmpty else {
            return false
        }
        return archive.thumbStatus != .genAvatar
    }

    private func waitForThumbnailIfNeeded(for archive: ArchiveVOData) async -> ArchiveVOData {
        guard !archiveHasUsableThumbnail(archive) else {
            return archive
        }

        var latestArchive = archive
        for _ in 0..<4 {
            try? await Task.sleep(nanoseconds: 600_000_000)
            let refreshedArchives = await fetchAccountArchives()
            if let refreshed = refreshedArchives.first(where: { $0.archiveID == archive.archiveID }) {
                latestArchive = refreshed
                availableArchives = refreshedArchives
                syncArchiveReferences(with: refreshedArchives)
                if archiveHasUsableThumbnail(refreshed) {
                    break
                }
            }
        }

        return latestArchive
    }

    func openCreateArchiveSheet() {
        resetCreateArchiveForm()
        showCreateArchiveSheet = true
    }

    func closeCreateArchiveSheet() {
        showCreateArchiveSheet = false
        showArchiveTypeSelection = false
    }

    func resetCreateArchiveForm() {
        newArchiveName = ""
        selectedArchiveType = .person
    }

    func openArchiveTypeSelection() {
        showArchiveTypeSelection = true
    }

    func closeArchiveTypeSelection() {
        showArchiveTypeSelection = false
    }

    func selectArchiveType(_ type: ArchiveType) {
        selectedArchiveType = type
        closeArchiveTypeSelection()
    }

    func isArchiveTypeSelected(_ type: ArchiveType) -> Bool {
        selectedArchiveType.tag == type.tag
    }

    func submitCreateArchive(completion: ((Bool) -> Void)? = nil) {
        createArchive(name: newArchiveName, type: selectedArchiveType) { [weak self] success in
            guard let self = self else { return }
            if success {
                self.closeCreateArchiveSheet()
                self.resetCreateArchiveForm()
            }
            completion?(success)
        }
    }
    
    func createArchive(name: String, type: ArchiveType, completion: ((Bool) -> Void)? = nil) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Archive name is required."
            isCreatingArchive = false
            completion?(false)
            return
        }
        
        let existingArchiveIDs = Set(availableArchives.compactMap { $0.archiveID })
        isLoading = true
        isCreatingArchive = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let outcome = try await createArchiveCoordinator.performCreateArchive(
                    name: trimmedName,
                    type: type,
                    existingArchiveIDs: existingArchiveIDs,
                    createArchiveRequest: { [repository] name, archiveType in
                        try await repository.createArchive(name: name, type: archiveType)
                    },
                    refreshArchives: { [weak self] in
                        guard let self = self else { return [] }
                        return await self.fetchAccountArchives()
                    },
                    resolveThumbnail: { [weak self] archive in
                        guard let self = self else { return archive }
                        return await self.waitForThumbnailIfNeeded(for: archive)
                    }
                )

                self.availableArchives = outcome.refreshedArchives
                self.syncArchiveReferences(with: outcome.refreshedArchives)

                if let selectedArchive = outcome.selectedArchive {
                    self.selectArchive(selectedArchive)
                } else {
                    self.isLoading = false
                }

                self.isCreatingArchive = false
                completion?(true)
            } catch {
                self.errorMessage = "Unable to create archive. Please try again."
                self.isLoading = false
                self.isCreatingArchive = false
                completion?(false)
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
        
        // Load V2 data using share token instead of share link ID.
        // Keep this non-blocking so core share metadata is populated immediately.
        Task { [weak self] in
            guard let self = self else { return }
            await self.loadV2ShareLinkData()
        }
        
        // Store temporary values
        var tempArchiveName = ""
        var tempCleanArchiveName = ""
        var tempThumbnailURL: String?
        var tempShareName = ""
        var tempSharedByName = ""
        var tempOriginalArchiveNbr: String?
        
        if let archive = shareByURL.archiveVO?.fullName {
            tempArchiveName = archive
            tempOriginalArchiveNbr = shareByURL.archiveVO?.archiveNbr
            tempCleanArchiveName = "The \(archive) Archive"
        }
        
        if let name = shareByURL.accountVO?.fullName {
            tempSharedByName = name
        }
        
        tempThumbnailURL = shareByURL.archiveVO?.thumbURL200
        tempShareName = shareByURL.recordData?.displayName ?? shareByURL.folderData?.displayName ?? ""
        
        _ = checkIfUserIsCreator(shareByURL: shareByURL)
        
        if let shareVO = shareByURL.shareVO {
            shareStatus = ShareStatus.status(forValue: shareVO.status)
        } else {
            shareStatus = .needsApproval
        }
        
        hasCompletedInitialLoad = true
        
        // Update visual properties at once after parsing is complete
        // Only update these if we have pending archive (meaning we're switching archives)
        if pendingArchive != nil {
            archiveName = tempArchiveName
            cleanArchiveName = tempCleanArchiveName
            thumbnailURL = tempThumbnailURL
            shareName = tempShareName
            sharedByName = tempSharedByName
            originalArchiveNbr = tempOriginalArchiveNbr
            if let pendingArchive = pendingArchive,
               let pendingId = pendingArchive.archiveID,
               let refreshedPending = availableArchives.first(where: { $0.archiveID == pendingId }) {
                displayedArchive = refreshedPending
            } else {
                displayedArchive = pendingArchive
            }
            pendingArchive = nil
        } else {
            // Initial load - update everything immediately
            archiveName = tempArchiveName
            cleanArchiveName = tempCleanArchiveName
            thumbnailURL = tempThumbnailURL
            shareName = tempShareName
            sharedByName = tempSharedByName
            originalArchiveNbr = tempOriginalArchiveNbr
            if let currentArchive = currentArchive,
               let currentId = currentArchive.archiveID,
               let refreshedCurrent = availableArchives.first(where: { $0.archiveID == currentId }) {
                displayedArchive = refreshedCurrent
            } else {
                displayedArchive = currentArchive
            }
        }
        
        currentButtonState = computedButtonState
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

struct FilePreviewParams {
    let name: String
    let recordId: Int
    let folderLinkId: Int
    let archiveNbr: String
    let type: String
    let thumbnailURL: String
}

// MARK: - Repository Protocol
protocol SharePreviewRepositoryProtocol {
    func fetchSharePreview(shareToken: String) async throws -> SharebyURLVOData
    func requestShareAccess(shareToken: String) async throws -> ShareVOData
    func createArchive(name: String, type: String) async throws
}

extension SharePreviewRepositoryProtocol {
    func createArchive(name: String, type: String) async throws {
        throw NSError(
            domain: "SharePreview",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Create archive not implemented for this repository"]
        )
    }
}

// MARK: - Production API Service
struct SharePreviewAPIService: SharePreviewRepositoryProtocol {
    func fetchSharePreview(shareToken: String) async throws -> SharebyURLVOData {
        let operation = APIOperation(ShareEndpoint.checkLink(token: shareToken))
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
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
            operation.cancel()
        })
    }
    
    func requestShareAccess(shareToken: String) async throws -> ShareVOData {
        let operation = APIOperation(ShareEndpoint.requestShareAccess(token: shareToken))
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
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
            operation.cancel()
        })
    }

    func createArchive(name: String, type: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let operation = APIOperation(ArchivesEndpoint.create(name: name, type: type))
            operation.execute(in: APIRequestDispatcher()) { result in
                switch result {
                case .json(let response, _):
                    guard
                        let model: APIResults<NoDataModel> = JSONHelper.decoding(
                            from: response,
                            with: APIResults<NoDataModel>.decoder
                        ),
                        model.isSuccessful
                    else {
                        continuation.resume(throwing: NSError(domain: "SharePreview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create archive"]))
                        return
                    }
                    continuation.resume(returning: ())

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

    func createArchive(name: String, type: String) async throws {
        // Mock no-op
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
