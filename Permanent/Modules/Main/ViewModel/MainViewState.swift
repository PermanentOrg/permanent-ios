//
//  MainViewState.swift
//  Permanent
//
//  Created for UIKit-to-SwiftUI Migration - Phase 1
//  State extraction layer for MainViewController
//  Updated 18.12.2025 - Phase 3: Navigation Migration support
//  Updated 19.12.2025 - Phase 4: Action Sheet Migration support
//  Updated 19.12.2025 - Phase 5: Coordinator and picker support
//

import Foundation
import Combine
import SwiftUI
import ObjectiveC

// MARK: - Toast Type

/// Toast message types for user feedback
enum ToastType {
    case error
    case success
    case info
    
    var backgroundColor: Color {
        switch self {
        case .error:
            return Color.red.opacity(0.9)
        case .success:
            return Color.green.opacity(0.9)
        case .info:
            return Color(UIColor.darkBlue).opacity(0.9)
        }
    }
    
    var icon: String {
        switch self {
        case .error:
            return "exclamationmark.triangle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
}

// MARK: - Permission Alert Type

/// Represents the types of permission alerts that can be presented.
enum PermissionAlertType: String, Identifiable {
    case camera
    case photoLibrary
    case storage
    
    var id: String { rawValue }
    
    /// The title for the permission alert
    var title: String {
        switch self {
        case .camera:
            return "Camera Access Required"
        case .photoLibrary:
            return "Photo Library Access Required"
        case .storage:
            return "Storage Access Required"
        }
    }
    
    /// The message for the permission alert
    var message: String {
        switch self {
        case .camera:
            return "Please allow camera access in Settings to take photos for upload."
        case .photoLibrary:
            return "Please allow photo library access in Settings to select photos for upload."
        case .storage:
            return "Please allow storage access in Settings to manage your files."
        }
    }
    
    /// The SF Symbol icon name for the permission type
    var iconName: String {
        switch self {
        case .camera:
            return "camera.fill"
        case .photoLibrary:
            return "photo.fill"
        case .storage:
            return "externaldrive.fill"
        }
    }
}

// MARK: - MainViewState Error

enum MainViewStateError: Error, LocalizedError {
    case folderNotFound
    case networkError(underlying: Error)
    case deletionFailed(message: String)
    case uploadFailed(message: String)
    case downloadFailed(message: String)
    case relocateFailed(message: String)
    case generic(message: String)
    
    var errorDescription: String? {
        switch self {
        case .folderNotFound:
            return "Folder not found"
        case .networkError(let underlying):
            return underlying.localizedDescription
        case .deletionFailed(let message):
            return message
        case .uploadFailed(let message):
            return message
        case .downloadFailed(let message):
            return message
        case .relocateFailed(let message):
            return message
        case .generic(let message):
            return message
        }
    }
}

// MARK: - MainViewState

/// ObservableObject that wraps FilesViewModel state for SwiftUI consumption.
/// Converts NotificationCenter observers to Combine publishers for reactive updates.
@available(iOS 17, *)
@MainActor
final class MainViewState: ObservableObject {
    
    // MARK: - Published State
    
    /// Current folder contents (synced files)
    @Published private(set) var files: [FileModel] = []
    
    /// Current folder location
    @Published private(set) var currentFolder: FileModel?
    
    /// Breadcrumb navigation path
    @Published private(set) var navigationPath: [FileModel] = []
    
    /// Set of folderLinkIds for selected files
    @Published var selectedFiles: Set<Int> = []
    
    /// Selection mode active
    @Published var isSelecting: Bool = false
    
    /// Current sort option
    @Published var sortOption: SortOption = .nameAscending
    
    /// Grid vs list view preference
    @Published var isGridView: Bool = false
    
    /// Files currently being uploaded (in current folder)
    @Published private(set) var uploadingFiles: [FileInfo] = []
    
    /// Files currently being downloaded
    @Published private(set) var downloadingFiles: [FileModel] = []
    
    /// Loading state
    @Published private(set) var isLoading: Bool = false
    
    /// Current error (nil when no error)
    @Published var error: MainViewStateError?
    
    /// Checkbox state for bulk selection
    @Published private(set) var checkboxState: CheckboxState = .none
    
    /// Flag indicating quota exceeded
    @Published private(set) var quotaExceeded: Bool = false
    
    // MARK: - SwiftUI Navigation State (Phase 3)
    
    /// SwiftUI NavigationStack path for folder navigation
    @Published var swiftUINavigationPath: [FileNavigationDestination] = []
    
    /// Flag indicating navigation is in progress (API call)
    @Published var isNavigating: Bool = false
    
    /// Toast message to display to user
    @Published var toastMessage: String? = nil
    
    /// Toast message type
    @Published var toastType: ToastType = .error
    
    // MARK: - Sheet Presentation State (Phase 4)
    
    /// Whether to show the sort options sheet
    @Published var showSortSheet: Bool = false
    
    /// Whether to show the upload options sheet
    @Published var showUploadSheet: Bool = false
    
    /// Whether to show the delete confirmation alert
    @Published var showDeleteAlert: Bool = false
    
    /// Files pending deletion (for delete confirmation)
    @Published var filesToDelete: [FileModel] = []
    
    /// Whether to show the cancel uploads alert
    @Published var showCancelUploadsAlert: Bool = false
    
    /// Number of pending uploads (for cancel uploads alert)
    @Published var pendingUploadCount: Int = 0
    
    /// Current permission alert type (nil = no alert)
    @Published var permissionAlert: PermissionAlertType? = nil
    
    // MARK: - Computed Properties
    
    /// Files currently selected as FileModel objects
    var selectedFileModels: [FileModel] {
        files.filter { selectedFiles.contains($0.folderLinkId) }
    }
    
    /// Whether current folder is root
    var isAtRoot: Bool {
        navigationPath.count <= 1
    }
    
    /// Whether there are any files to display
    var isEmpty: Bool {
        files.isEmpty && uploadingFiles.isEmpty
    }
    
    /// Archive permissions from current session
    var archivePermissions: [Permission] {
        filesViewModel?.archivePermissions ?? [.read]
    }
    
    /// Archive access role
    var archiveAccessRole: AccessRole {
        filesViewModel?.archiveAccessRole ?? .viewer
    }
    
    /// Root folder name for display
    var rootFolderName: String {
        if let myFilesVM = filesViewModel as? MyFilesViewModel {
            return myFilesVM.rootFolderName
        } else if let publicFilesVM = filesViewModel as? PublicFilesViewModel {
            return publicFilesVM.rootFolderName
        }
        return "Files"
    }
    
    // MARK: - Dependencies
    
    /// Reference to the underlying FilesViewModel (MyFilesViewModel or PublicFilesViewModel)
    private weak var filesViewModel: FilesViewModel?
    
    /// Combine cancellables storage
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(filesViewModel: FilesViewModel) {
        self.filesViewModel = filesViewModel
        syncFromViewModel()
        setupNotificationSubscriptions()
    }
    
    // MARK: - State Synchronization
    
    /// Syncs state from the underlying FilesViewModel
    func syncFromViewModel() {
        guard let vm = filesViewModel else { return }
        
        files = vm.viewModels
        navigationPath = vm.navigationStack
        currentFolder = vm.currentFolder
        sortOption = vm.activeSortOption
        isGridView = vm.isGridView
        uploadingFiles = vm.queueItemsForCurrentFolder
        downloadingFiles = vm.downloadQueue
        isSelecting = vm.isSelecting
        checkboxState = vm.checkboxState
        
        // Sync selected files from session
        if let sessionSelectedFiles = vm.selectedFiles {
            selectedFiles = Set(sessionSelectedFiles.map { $0.folderLinkId })
        } else {
            selectedFiles = []
        }
    }
    
    /// Loads the initial root folder data
    /// This must be called when the SwiftUI view appears to fetch the root files
    @MainActor
    func loadInitialData() async {
        // Check if data is already loaded
        guard files.isEmpty, !isLoading else {
            return
        }
        
        guard let myFilesVM = filesViewModel as? MyFilesViewModel else {
            // For non-MyFiles view models, just sync existing data
            syncFromViewModel()
            return
        }
        
        isLoading = true
        
        // Bridge the callback-based getRoot() to async/await
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            myFilesVM.getRoot { [weak self] status in
                Task { @MainActor in
                    guard let self = self else {
                        continuation.resume()
                        return
                    }
                    
                    switch status {
                    case .success:
                        // Sync the newly loaded data
                        self.syncFromViewModel()
                        
                    case .error(let message):
                        self.error = .generic(message: message ?? "Failed to load files")
                        self.showToast(message: message ?? "Failed to load files", type: .error)
                    }
                    
                    self.isLoading = false
                    continuation.resume()
                }
            }
        }
    }
    
    /// Updates the underlying FilesViewModel with current state
    private func syncToViewModel() {
        guard let vm = filesViewModel else { return }
        
        vm.activeSortOption = sortOption
        vm.isGridView = isGridView
        vm.isSelecting = isSelecting
        
        // Sync selected files back
        vm.selectedFiles = selectedFileModels
    }
    
    // MARK: - Notification Subscriptions
    
    private func setupNotificationSubscriptions() {
        // Upload queue refresh
        NotificationCenter.default.publisher(for: UploadManager.didRefreshQueueNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleUploadQueueRefresh()
            }
            .store(in: &cancellables)
        
        // Quota exceeded
        NotificationCenter.default.publisher(for: UploadManager.quotaExceededNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.quotaExceeded = true
            }
            .store(in: &cancellables)
        
        // Mobile uploads folder created
        NotificationCenter.default.publisher(for: UploadManager.didCreateMobileUploadsFolderNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleMobileUploadsFolderCreated(notification)
            }
            .store(in: &cancellables)
        
        // Upload finished
        NotificationCenter.default.publisher(for: UploadOperation.uploadFinishedNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleUploadFinished(notification)
            }
            .store(in: &cancellables)
        
        // Upload progress
        NotificationCenter.default.publisher(for: UploadOperation.uploadProgressNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleUploadProgress(notification)
            }
            .store(in: &cancellables)
        
        // Shares updated
        NotificationCenter.default.publisher(for: ShareLinkViewModel.didUpdateSharesNotifName)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleSharesUpdated(notification)
            }
            .store(in: &cancellables)
        
        // Files selection changed
        NotificationCenter.default.publisher(for: MyFilesViewModel.didSelectFilesNotifName)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleFilesSelectionChanged(notification)
            }
            .store(in: &cancellables)
        
        // Archive changed
        NotificationCenter.default.publisher(for: ArchivesViewModel.didChangeArchiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleArchiveChanged()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Notification Handlers
    
    private func handleUploadQueueRefresh() {
        guard let vm = filesViewModel else { return }
        
        if vm.refreshUploadQueue() && !vm.queueItemsForCurrentFolder.isEmpty {
            uploadingFiles = vm.queueItemsForCurrentFolder
        }
    }
    
    private func handleMobileUploadsFolderCreated(_ notification: Notification) {
        guard let folder = notification.userInfo?["folder"] as? MinFolderVO,
              currentFolder?.folderId == folder.parentFolderID else { return }
        
        // Trigger refresh of current folder
        Task {
            await refreshCurrentFolder()
        }
    }
    
    private func handleUploadFinished(_ notification: Notification) {
        guard let operation = notification.object as? UploadOperation,
              let vm = filesViewModel else { return }
        
        // Check if upload is in current folder
        guard currentFolder?.folderLinkId == operation.file.folder.folderLinkId else { return }
        
        if notification.userInfo?["error"] == nil, let uploadedFile = operation.uploadedFile {
            // Remove from upload queue
            vm.uploadQueue.removeAll { $0 == operation.file }
            
            // Add uploaded file to view models
            let newFileModel = FileModel(
                model: uploadedFile,
                archiveThumbnailURL: "",
                permissions: archivePermissions,
                accessRole: archiveAccessRole
            )
            vm.viewModels.insert(newFileModel, at: 0)
            
            syncFromViewModel()
        } else {
            // Upload failed - refresh queue
            vm.refreshUploadQueue()
            syncFromViewModel()
        }
    }
    
    private func handleUploadProgress(_ notification: Notification) {
        guard let operation = notification.object as? UploadOperation,
              let vm = filesViewModel else { return }
        
        if currentFolder?.folderLinkId == operation.file.folder.folderLinkId {
            vm.invalidateTimer()
        }
    }
    
    private func handleSharesUpdated(_ notification: Notification) {
        guard let shareLinkVM = notification.object as? ShareLinkViewModel,
              let vm = filesViewModel,
              let index = vm.viewModels.firstIndex(where: { $0.recordId == shareLinkVM.fileViewModel.recordId })
        else { return }
        
        vm.viewModels[index].accessRole = shareLinkVM.fileViewModel.accessRole
        vm.viewModels[index].minArchiveVOS = shareLinkVM.fileViewModel.minArchiveVOS
        
        syncFromViewModel()
    }
    
    private func handleFilesSelectionChanged(_ notification: Notification) {
        guard let showFloatingIsland = notification.userInfo?["showFloatingIsland"] as? Bool else { return }
        
        // Update local selection state
        isSelecting = showFloatingIsland || !selectedFiles.isEmpty
        syncFromViewModel()
    }
    
    private func handleArchiveChanged() {
        // Archive changed - reset to root
        guard let vm = filesViewModel else { return }
        
        _ = vm.removeCurrentFolderFromHierarchy()
        
        // Clear state
        files = []
        navigationPath = []
        currentFolder = nil
        selectedFiles = []
        isSelecting = false
        
        // Note: The ViewController should handle refreshing the root folder
    }
    
    // MARK: - Public Methods for State Updates
    
    /// Clears the quota exceeded flag
    func clearQuotaExceeded() {
        quotaExceeded = false
    }
    
    /// Clears the current error
    func clearError() {
        error = nil
    }
    
    /// Sets loading state
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    /// Updates files from external source
    func updateFiles(_ newFiles: [FileModel]) {
        files = newFiles
        filesViewModel?.viewModels = newFiles
    }
    
    /// Updates the navigation path
    func updateNavigationPath(_ path: [FileModel]) {
        navigationPath = path
        currentFolder = path.last
    }
    
    /// Refreshes current folder state from view model
    @MainActor
    func refreshCurrentFolder() async {
        guard filesViewModel != nil else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        // Re-sync state from view model
        syncFromViewModel()
    }
    
    /// Updates selection state
    func updateSelection(isSelecting: Bool) {
        self.isSelecting = isSelecting
        filesViewModel?.isSelecting = isSelecting
        
        if !isSelecting {
            selectedFiles = []
            filesViewModel?.selectedFiles = []
        }
    }
    
    /// Toggles selection for a file
    func toggleFileSelection(_ file: FileModel) {
        if selectedFiles.contains(file.folderLinkId) {
            selectedFiles.remove(file.folderLinkId)
        } else {
            selectedFiles.insert(file.folderLinkId)
        }
        
        // Sync to view model
        filesViewModel?.selectedFiles = selectedFileModels
        updateCheckboxState()
    }
    
    /// Updates checkbox state based on current selection
    private func updateCheckboxState() {
        if selectedFiles.isEmpty {
            checkboxState = .none
        } else if selectedFiles.count == files.count {
            checkboxState = .selected
        } else {
            checkboxState = .partial
        }
        
        filesViewModel?.checkboxState = checkboxState
    }
    
    /// Updates sort option and syncs to view model
    func updateSortOption(_ option: SortOption) {
        sortOption = option
        filesViewModel?.activeSortOption = option
    }
    
    /// Updates grid view preference and syncs to view model
    func updateGridView(_ isGrid: Bool) {
        isGridView = isGrid
        filesViewModel?.isGridView = isGrid
    }
}

// MARK: - MainViewState + Actions Conformance

@available(iOS 17, *)
extension MainViewState: MainViewActions {
    
    func navigateToFolder(_ folder: FileModel) {
        guard folder.type.isFolder else { return }
        
        navigationPath.append(folder)
        currentFolder = folder
        
        // Update view model
        filesViewModel?.navigationStack = navigationPath
    }
    
    func navigateBack() {
        guard navigationPath.count > 1 else { return }
        
        navigationPath.removeLast()
        currentFolder = navigationPath.last
        
        // Update view model
        filesViewModel?.navigationStack = navigationPath
    }
    
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        
        // Note: Actual network call should be handled by the coordinator/view controller
        // This state object just manages the state
        syncFromViewModel()
    }
    
    func selectFile(_ file: FileModel) {
        selectedFiles.insert(file.folderLinkId)
        filesViewModel?.selectedFiles = selectedFileModels
        updateCheckboxState()
    }
    
    func deselectFile(_ file: FileModel) {
        selectedFiles.remove(file.folderLinkId)
        filesViewModel?.selectedFiles = selectedFileModels
        updateCheckboxState()
    }
    
    func toggleSelection() {
        isSelecting.toggle()
        filesViewModel?.isSelecting = isSelecting
        
        if !isSelecting {
            clearSelection()
        }
    }
    
    func clearSelection() {
        selectedFiles = []
        filesViewModel?.selectedFiles = []
        updateCheckboxState()
    }
    
    func selectAllFiles() {
        selectedFiles = Set(files.map { $0.folderLinkId })
        filesViewModel?.selectedFiles = selectedFileModels
        updateCheckboxState()
    }
    
    func setSortOption(_ option: SortOption) {
        updateSortOption(option)
    }
    
    func toggleGridView() {
        updateGridView(!isGridView)
    }
    
    func deleteSelectedFiles() {
        guard !selectedFiles.isEmpty else { return }
        
        // Note: Actual deletion is handled by the coordinator/view controller
        // This provides the data for the operation
    }
    
    func copySelectedFiles() {
        guard !selectedFiles.isEmpty else { return }
        
        filesViewModel?.fileAction = .copy
    }
    
    func moveSelectedFiles() {
        guard !selectedFiles.isEmpty else { return }
        
        filesViewModel?.fileAction = .move
    }
    
    func downloadFile(_ file: FileModel) {
        // Note: Actual download is handled by the coordinator/view controller
        var downloadFile = file
        downloadFile.fileStatus = .downloading
        downloadingFiles.append(downloadFile)
    }
    
    func uploadFiles(_ urls: [URL]) {
        guard filesViewModel != nil else { return }
        // Note: Actual upload is handled by the coordinator/view controller
        // This just provides the interface for triggering uploads
    }
}

// MARK: - MainViewState + SwiftUI Navigation (Phase 3)

@available(iOS 17, *)
extension MainViewState {
    
    /// Navigates to a folder asynchronously, performing the API call
    /// - Parameters:
    ///   - archiveNo: The archive number of the folder
    ///   - folderLinkId: The folder link ID
    ///   - name: The display name of the folder
    func navigateToFolderAsync(archiveNo: String, folderLinkId: Int, name: String) async {
        guard let vm = filesViewModel else {
            showToast(message: "Navigation unavailable", type: .error)
            return
        }
        
        isNavigating = true
        
        // Create the navigation params
        let params: NavigateMinParams = (archiveNo, folderLinkId, name)
        
        // Bridge callback-based API to async/await
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            vm.navigateMin(params: params, backNavigation: false) { [weak self] status in
                Task { @MainActor in
                    guard let self = self else {
                        continuation.resume()
                        return
                    }
                    
                    switch status {
                    case .success:
                        // Append to SwiftUI navigation path
                        let destination = FileNavigationDestination.folder(
                            archiveNo: archiveNo,
                            folderLinkId: folderLinkId,
                            name: name
                        )
                        self.swiftUINavigationPath.append(destination)
                        
                        // Sync state from view model
                        self.syncFromViewModel()
                        
                    case .error(let message):
                        // Show toast error but do NOT pop path
                        self.showToast(message: message ?? "Failed to navigate to folder", type: .error)
                    }
                    
                    self.isNavigating = false
                    continuation.resume()
                }
            }
        }
    }
    
    /// Navigates back from SwiftUI navigation path
    func navigateBackFromSwiftUI() {
        guard !swiftUINavigationPath.isEmpty else { return }
        
        // Pop from SwiftUI path
        swiftUINavigationPath.removeLast()
        
        // Also update the underlying view model's navigation stack
        _ = filesViewModel?.removeCurrentFolderFromHierarchy()
        
        // Sync state from view model
        syncFromViewModel()
    }
    
    /// Handles deep link navigation to a shared folder
    /// - Parameter shareToken: The share token from the deep link
    func navigateToDeepLink(shareToken: String) async {
        isNavigating = true
        
        // Add deep link destination to path
        let destination = FileNavigationDestination.deepLink(shareToken: shareToken)
        swiftUINavigationPath.append(destination)
        
        // Note: Deep link resolution should be handled by the coordinator
        // This just manages the navigation state
        
        isNavigating = false
    }
    
    /// Shows a toast message
    /// - Parameters:
    ///   - message: The message to display
    ///   - type: The toast type (error, success, info)
    func showToast(message: String, type: ToastType = .error) {
        toastMessage = message
        toastType = type
    }
    
    /// Dismisses the current toast message
    func dismissToast() {
        toastMessage = nil
    }
    
    /// Resets the SwiftUI navigation path to root
    func resetNavigationToRoot() {
        swiftUINavigationPath.removeAll()
        
        // Also reset the underlying view model
        while filesViewModel?.navigationStack.count ?? 0 > 1 {
            _ = filesViewModel?.removeCurrentFolderFromHierarchy()
        }
        
        syncFromViewModel()
    }
    
    /// Checks if currently at root in SwiftUI navigation
    var isAtSwiftUIRoot: Bool {
        swiftUINavigationPath.isEmpty
    }
    
    /// Gets the current folder name for display
    var currentFolderDisplayName: String {
        if let lastDestination = swiftUINavigationPath.last {
            return lastDestination.displayName
        }
        return rootFolderName
    }
}

// MARK: - MainViewState + Sheet Presentation (Phase 4)

@available(iOS 17, *)
extension MainViewState {
    
    /// Presents the sort options sheet
    func presentSortSheet() {
        showSortSheet = true
    }
    
    /// Presents the upload options sheet
    func presentUploadSheet() {
        showUploadSheet = true
    }
    
    /// Presents delete confirmation alert for specified files
    /// - Parameter files: The files to delete
    func presentDeleteConfirmation(for files: [FileModel]) {
        guard !files.isEmpty else { return }
        
        filesToDelete = files
        showDeleteAlert = true
    }
    
    /// Presents delete confirmation alert for currently selected files
    func presentDeleteConfirmationForSelection() {
        presentDeleteConfirmation(for: selectedFileModels)
    }
    
    /// Presents the cancel uploads alert
    /// - Parameter count: The number of pending uploads
    func presentCancelUploadsAlert(count: Int) {
        guard count > 0 else { return }
        
        pendingUploadCount = count
        showCancelUploadsAlert = true
    }
    
    /// Presents the cancel uploads alert for current upload queue
    func presentCancelUploadsAlertForCurrentQueue() {
        presentCancelUploadsAlert(count: uploadingFiles.count)
    }
    
    /// Presents a permission alert for the specified type
    /// - Parameter type: The permission type that requires user action
    func presentPermissionAlert(_ type: PermissionAlertType) {
        permissionAlert = type
    }
    
    /// Dismisses the sort sheet
    func dismissSortSheet() {
        showSortSheet = false
    }
    
    /// Dismisses the upload sheet
    func dismissUploadSheet() {
        showUploadSheet = false
    }
    
    /// Dismisses the delete alert and clears files to delete
    func dismissDeleteAlert() {
        showDeleteAlert = false
        filesToDelete = []
    }
    
    /// Dismisses the cancel uploads alert
    func dismissCancelUploadsAlert() {
        showCancelUploadsAlert = false
        pendingUploadCount = 0
    }
    
    /// Dismisses the permission alert
    func dismissPermissionAlert() {
        permissionAlert = nil
    }
}

// MARK: - MainViewState + Phase 5 Picker & Search Support

@available(iOS 17, *)
extension MainViewState {
    
    // MARK: - Picker State Properties
    
    /// Whether to show the photo picker
    /// Note: Using computed property with backing storage in filesViewModel or separate state
    var showPhotoPicker: Bool {
        get { _showPhotoPicker }
        set { _showPhotoPicker = newValue }
    }
    
    /// Whether to show the document picker
    var showDocumentPicker: Bool {
        get { _showDocumentPicker }
        set { _showDocumentPicker = newValue }
    }
    
    /// Whether to show the camera picker
    var showCameraPicker: Bool {
        get { _showCameraPicker }
        set { _showCameraPicker = newValue }
    }
    
    /// File to preview (nil if no preview active)
    var fileToPreview: FileModel? {
        get { _fileToPreview }
        set { _fileToPreview = newValue }
    }
    
    /// Search text for filtering files
    var searchText: String {
        get { _searchText }
        set { _searchText = newValue }
    }
    
    // MARK: - Computed Properties
    
    /// Files filtered by search text
    var filteredFiles: [FileModel] {
        guard !searchText.isEmpty else {
            return files
        }
        
        let lowercasedSearch = searchText.lowercased()
        return files.filter { file in
            file.name.lowercased().contains(lowercasedSearch) ||
            file.description.lowercased().contains(lowercasedSearch)
        }
    }
    
    /// Files to display (either filtered or all)
    var displayFiles: [FileModel] {
        return filteredFiles
    }
    
    // MARK: - Picker Presentation Methods
    
    /// Presents the photo picker
    func presentPhotoPicker() {
        showPhotoPicker = true
    }
    
    /// Dismisses the photo picker
    func dismissPhotoPicker() {
        showPhotoPicker = false
    }
    
    /// Presents the document picker
    func presentDocumentPicker() {
        showDocumentPicker = true
    }
    
    /// Dismisses the document picker
    func dismissDocumentPicker() {
        showDocumentPicker = false
    }
    
    /// Presents the camera picker
    func presentCameraPicker() {
        showCameraPicker = true
    }
    
    /// Dismisses the camera picker
    func dismissCameraPicker() {
        showCameraPicker = false
    }
    
    /// Sets the file to preview
    /// - Parameter file: The file to preview, or nil to clear
    func setFileToPreview(_ file: FileModel?) {
        fileToPreview = file
    }
    
    /// Clears the file to preview
    func dismissFilePreview() {
        fileToPreview = nil
    }
    
    /// Clears the search text
    func clearSearch() {
        searchText = ""
    }
}

// MARK: - MainViewState + FloatingActionIsland Support (Phase 5)

@available(iOS 17, *)
extension MainViewState {
    
    // MARK: - Coordinator Reference
    
    /// Reference to the coordinator for delegating actions
    var coordinator: MainViewCoordinator? {
        get { _coordinator }
        set { _coordinator = newValue }
    }
    
    // MARK: - Bulk Selection Actions
    
    /// Moves the currently selected files
    /// Delegates to coordinator for destination selection
    func moveSelectedFilesAction() {
        guard !selectedFiles.isEmpty else {
            showToast(message: "No files selected", type: .info)
            return
        }
        
        coordinator?.moveFiles(selectedFileModels)
    }
    
    /// Copies the currently selected files
    /// Delegates to coordinator for destination selection
    func copySelectedFilesAction() {
        guard !selectedFiles.isEmpty else {
            showToast(message: "No files selected", type: .info)
            return
        }
        
        coordinator?.copyFiles(selectedFileModels)
    }
    
    /// Shares the currently selected files
    /// Delegates to coordinator for share presentation
    func shareSelectedFilesAction() {
        guard !selectedFiles.isEmpty else {
            showToast(message: "No files selected", type: .info)
            return
        }
        
        coordinator?.shareFiles(selectedFileModels)
    }
    
    /// Downloads the currently selected files
    /// Delegates to coordinator for download handling
    func downloadSelectedFilesAction() {
        guard !selectedFiles.isEmpty else {
            showToast(message: "No files selected", type: .info)
            return
        }
        
        // Filter out folders - they can't be downloaded directly
        let downloadableFiles = selectedFileModels.filter { !$0.type.isFolder }
        
        guard !downloadableFiles.isEmpty else {
            showToast(message: "Selected items cannot be downloaded", type: .info)
            return
        }
        
        coordinator?.downloadFiles(downloadableFiles)
    }
    
    /// Deletes the currently selected files
    /// Shows confirmation dialog before deletion
    func deleteSelectedFilesAction() {
        guard !selectedFiles.isEmpty else {
            showToast(message: "No files selected", type: .info)
            return
        }
        
        presentDeleteConfirmation(for: selectedFileModels)
    }
    
    /// Publishes the currently selected files to public gallery
    /// Note: This functionality should be implemented via coordinator
    /// when the publish feature is migrated to SwiftUI
    func publishSelectedFiles() {
        guard !selectedFiles.isEmpty else {
            showToast(message: "No files selected", type: .info)
            return
        }
        
        // Delegate to coordinator for publish handling
        // The coordinator will access the filesViewModel
        showToast(message: "Publishing \(selectedFileModels.count) item(s)...", type: .info)
        
        // Note: Full implementation requires coordinator.publishFiles(selectedFileModels)
        // which will be added when the publish feature is migrated
    }
}

// MARK: - MainViewState Private Storage Extension

/// Private storage for Phase 5 properties
/// Using a separate extension to add stored properties via associated objects
@available(iOS 17, *)
extension MainViewState {
    
    private static var showPhotoPickerKey: UInt8 = 0
    private static var showDocumentPickerKey: UInt8 = 1
    private static var showCameraPickerKey: UInt8 = 2
    private static var fileToPreviewKey: UInt8 = 3
    private static var searchTextKey: UInt8 = 4
    private static var coordinatorKey: UInt8 = 5
    
    private var _showPhotoPicker: Bool {
        get {
            return objc_getAssociatedObject(self, &Self.showPhotoPickerKey) as? Bool ?? false
        }
        set {
            objectWillChange.send()
            objc_setAssociatedObject(self, &Self.showPhotoPickerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var _showDocumentPicker: Bool {
        get {
            return objc_getAssociatedObject(self, &Self.showDocumentPickerKey) as? Bool ?? false
        }
        set {
            objectWillChange.send()
            objc_setAssociatedObject(self, &Self.showDocumentPickerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var _showCameraPicker: Bool {
        get {
            return objc_getAssociatedObject(self, &Self.showCameraPickerKey) as? Bool ?? false
        }
        set {
            objectWillChange.send()
            objc_setAssociatedObject(self, &Self.showCameraPickerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var _fileToPreview: FileModel? {
        get {
            return objc_getAssociatedObject(self, &Self.fileToPreviewKey) as? FileModel
        }
        set {
            objectWillChange.send()
            objc_setAssociatedObject(self, &Self.fileToPreviewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var _searchText: String {
        get {
            return objc_getAssociatedObject(self, &Self.searchTextKey) as? String ?? ""
        }
        set {
            objectWillChange.send()
            objc_setAssociatedObject(self, &Self.searchTextKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var _coordinator: MainViewCoordinator? {
        get {
            return objc_getAssociatedObject(self, &Self.coordinatorKey) as? MainViewCoordinator
        }
        set {
            objc_setAssociatedObject(self, &Self.coordinatorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
