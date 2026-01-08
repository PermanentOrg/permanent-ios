//
//  SwiftUIMainView.swift
//  Permanent
//
//  Created on 19.12.2025
//  Phase 5 Part 4: SwiftUI Main Container View
//
//  This is the top-level SwiftUI container view that integrates all components
//  from Phases 1-5 of the UIKit-to-SwiftUI migration.
//

import SwiftUI
import PhotosUI

// MARK: - SwiftUIMainView

/// The main SwiftUI container view that brings together all migration components.
/// Integrates NavigationStack, Toolbar, Search, File List, Floating Action Island,
/// Action Sheets, Pickers, and Preview views.
@available(iOS 17, *)
struct SwiftUIMainView: View {
    
    // MARK: - State
    
    /// Main view state (observable from MainViewState)
    @StateObject private var state: MainViewState
    
    /// Search text binding for native search
    @State private var searchText: String = ""
    
    /// Whether search is currently active
    @State private var isSearchActive: Bool = false
    
    // MARK: - Picker Presentation States
    
    /// Show photo library picker
    @State private var showPhotoPicker: Bool = false
    
    /// Show document picker
    @State private var showDocumentPicker: Bool = false
    
    /// Show camera picker
    @State private var showCameraPicker: Bool = false
    
    /// Selected photo items from PhotosPicker
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    
    // MARK: - Preview Presentation
    
    /// File currently being previewed (nil = no preview)
    @State private var fileToPreview: FileModel? = nil
    
    // MARK: - Coordinator
    
    /// Coordinator for handling file list actions
    weak var coordinator: EnhancedFileListCoordinatorProtocol?
    
    // MARK: - Callbacks
    
    /// Callback when photos are selected from library
    var onPhotosSelected: (([PhotosPickerItem]) -> Void)?
    
    /// Callback when documents are selected
    var onDocumentsSelected: (([URL]) -> Void)?
    
    /// Callback when an image is captured from camera
    var onImageCaptured: ((UIImage) -> Void)?
    
    /// Callback when a video is captured from camera
    var onVideoCaptured: ((URL) -> Void)?
    
    /// Callback for move action
    var onMoveAction: (() -> Void)?
    
    /// Callback for copy action
    var onCopyAction: (() -> Void)?
    
    /// Callback for share action
    var onShareAction: (() -> Void)?
    
    /// Callback for download action
    var onDownloadAction: (() -> Void)?
    
    // MARK: - Initialization
    
    /// Creates a new SwiftUIMainView
    /// - Parameter viewModel: The FilesViewModel to wrap (MyFilesViewModel or PublicFilesViewModel)
    init(viewModel: FilesViewModel) {
        _state = StateObject(wrappedValue: MainViewState(filesViewModel: viewModel))
    }
    
    // MARK: - Body
    
    var body: some View {
        mainContent
            // Searchable modifier for native search
            .searchable(
                text: $searchText,
                isPresented: $isSearchActive,
                prompt: "Search files"
            )
            .onChange(of: searchText) { _, newValue in
                filterFiles(searchText: newValue)
            }
            // Action sheets from Phase 4
            .sortActionSheet(
                isPresented: $state.showSortSheet,
                selection: $state.sortOption
            )
            .uploadOptionsSheet(
                isPresented: $state.showUploadSheet,
                onSelect: handleUploadSourceSelection
            )
            .deleteConfirmationAlert(
                isPresented: $state.showDeleteAlert,
                itemCount: state.filesToDelete.count,
                onConfirm: handleDeleteConfirmation
            )
            .cancelUploadsAlert(
                isPresented: $state.showCancelUploadsAlert,
                pendingCount: state.pendingUploadCount,
                onConfirm: handleCancelUploads
            )
            .permissionAlert(permissionType: $state.permissionAlert)
            // Picker sheets
            .sheet(isPresented: $showPhotoPicker) {
                photoPickerSheet
            }
            .sheet(isPresented: $showDocumentPicker) {
                documentPickerSheet
            }
            .fullScreenCover(isPresented: $showCameraPicker) {
                cameraPickerSheet
            }
            // File preview
            .fullScreenCover(item: $fileToPreview) { file in
                filePreviewSheet(file: file)
            }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            // Navigation container with folder content
            navigationContent
            
            // Floating action island overlay
            FloatingActionIslandView(
                state: state,
                onMoveAction: onMoveAction,
                onCopyAction: onCopyAction,
                onShareAction: onShareAction,
                onDownloadAction: onDownloadAction
            )
            .padding(.bottom, 8)
        }
    }
    
    // MARK: - Navigation Content
    
    @ViewBuilder
    private var navigationContent: some View {
        NavigationStack(path: $state.swiftUINavigationPath) {
            // Root content
            fileListView
                .navigationDestination(for: FileNavigationDestination.self) { destination in
                    fileListView
                        .navigationTitle(destination.displayName)
                }
                .navigationTitle(state.rootFolderName)
                .navigationBarTitleDisplayMode(.inline)
                .mainViewToolbar(
                    state: state,
                    onBackTapped: {
                        state.navigateBackFromSwiftUI()
                    },
                    onSearchToggled: {
                        isSearchActive.toggle()
                    }
                )
        }
        // Navigation loading overlay
        .overlay(alignment: .center) {
            navigationLoadingOverlay
        }
        // Toast overlay
        .overlay(alignment: .bottom) {
            toastOverlay
        }
    }
    
    // MARK: - File List View
    
    @ViewBuilder
    private var fileListView: some View {
        EnhancedFileListView(
            state: state,
            coordinator: coordinator,
            onFolderTap: { folder in
                handleFolderTap(folder)
            }
        )
        .onAppear {
            // Load initial data when view first appears
            Task {
                await state.loadInitialData()
            }
        }
        .onTapGesture(count: 2) {
            // Double tap handled by EnhancedFileListView
        }
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    // Single tap for file preview is handled below
                }
        )
    }
    
    // MARK: - Navigation Loading Overlay
    
    @ViewBuilder
    private var navigationLoadingOverlay: some View {
        if state.isNavigating {
            ZStack {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(UIColor.darkBlue)))
                        .scaleEffect(1.5)
                    
                    Text("Loading folder...")
                        .font(.custom("Usual-Regular", size: 14))
                        .foregroundColor(Color(UIColor.darkBlue))
                }
                .padding(32)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: state.isNavigating)
        }
    }
    
    // MARK: - Toast Overlay
    
    @ViewBuilder
    private var toastOverlay: some View {
        if let message = state.toastMessage {
            ToastView(
                message: message,
                type: state.toastType,
                onDismiss: {
                    state.dismissToast()
                }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, state.selectedFiles.isEmpty ? 24 : 120) // Account for floating island
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: state.toastMessage)
            .onAppear {
                // Auto-dismiss after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    state.dismissToast()
                }
            }
        }
    }
    
    // MARK: - Photo Picker Sheet
    
    @ViewBuilder
    private var photoPickerSheet: some View {
        NavigationStack {
            PhotosPicker(
                selection: $selectedPhotoItems,
                maxSelectionCount: nil,
                matching: .any(of: [.images, .videos]),
                photoLibrary: .shared()
            ) {
                VStack(spacing: 16) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 64))
                        .foregroundColor(Color(UIColor.primary))
                    
                    Text("Tap to select photos and videos")
                        .font(.custom("Usual-Regular", size: 17))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Select Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showPhotoPicker = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        handlePhotosSelected()
                    }
                    .disabled(selectedPhotoItems.isEmpty)
                }
            }
        }
        .onChange(of: selectedPhotoItems) { _, newValue in
            if !newValue.isEmpty {
                handlePhotosSelected()
            }
        }
    }
    
    // MARK: - Document Picker Sheet
    
    @ViewBuilder
    private var documentPickerSheet: some View {
        DocumentPickerView(
            contentTypes: [.item, .content],
            allowsMultipleSelection: true,
            onDocumentsPicked: { urls in
                onDocumentsSelected?(urls)
                showDocumentPicker = false
            },
            onCancel: {
                showDocumentPicker = false
            }
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Camera Picker Sheet
    
    @ViewBuilder
    private var cameraPickerSheet: some View {
        if CameraPickerView.isCameraAvailable {
            CameraPickerView(
                mediaTypes: [UTType.image.identifier, UTType.movie.identifier],
                onImageCaptured: { image in
                    onImageCaptured?(image)
                    showCameraPicker = false
                },
                onVideoCaptured: { url in
                    onVideoCaptured?(url)
                    showCameraPicker = false
                },
                onCancel: {
                    showCameraPicker = false
                },
                onError: { error in
                    state.showToast(message: error.localizedDescription, type: .error)
                    showCameraPicker = false
                }
            )
            .ignoresSafeArea()
        } else {
            // Camera not available - show error
            VStack(spacing: 24) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                
                Text("Camera Not Available")
                    .font(.custom("Usual-Medium", size: 20))
                
                Text("This device does not have a camera or camera access is restricted.")
                    .font(.custom("Usual-Regular", size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button("Dismiss") {
                    showCameraPicker = false
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
        }
    }
    
    // MARK: - File Preview Sheet
    
    @ViewBuilder
    private func filePreviewSheet(file: FileModel) -> some View {
        NavigationStack {
            FilePreviewView(file: file)
                .onDismiss {
                    fileToPreview = nil
                }
                .navigationTitle(file.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            fileToPreview = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                // Share action
                                onShareAction?()
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            
                            Button {
                                // Download action
                                state.downloadFile(file)
                            } label: {
                                Label("Download", systemImage: "arrow.down.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                }
        }
    }
    
    // MARK: - Actions
    
    /// Handles folder tap for navigation
    private func handleFolderTap(_ folder: FileModel) {
        guard folder.type.isFolder else {
            // Not a folder - show preview
            handleFileTap(folder)
            return
        }
        
        // Trigger async navigation
        Task {
            await state.navigateToFolderAsync(
                archiveNo: folder.archiveNo,
                folderLinkId: folder.folderLinkId,
                name: folder.name
            )
        }
    }
    
    /// Handles file tap for preview
    private func handleFileTap(_ file: FileModel) {
        guard !file.type.isFolder else { return }
        
        // Set file to preview (triggers fullScreenCover)
        fileToPreview = file
    }
    
    /// Handles upload source selection from upload options sheet
    private func handleUploadSourceSelection(_ source: UploadSource) {
        switch source {
        case .photoLibrary:
            // Check permission first
            checkPhotoLibraryPermission { granted in
                if granted {
                    showPhotoPicker = true
                } else {
                    state.presentPermissionAlert(.photoLibrary)
                }
            }
            
        case .files:
            showDocumentPicker = true
            
        case .camera:
            // Check permission first
            checkCameraPermission { granted in
                if granted {
                    showCameraPicker = true
                } else {
                    state.presentPermissionAlert(.camera)
                }
            }
        }
    }
    
    /// Handles photos selected from picker
    private func handlePhotosSelected() {
        guard !selectedPhotoItems.isEmpty else { return }
        
        onPhotosSelected?(selectedPhotoItems)
        
        // Clear selection and dismiss
        selectedPhotoItems = []
        showPhotoPicker = false
    }
    
    /// Handles delete confirmation
    private func handleDeleteConfirmation() {
        // Delegate to coordinator or perform deletion
        state.deleteSelectedFiles()
        state.dismissDeleteAlert()
        state.clearSelection()
        state.updateSelection(isSelecting: false)
    }
    
    /// Handles cancel uploads confirmation
    private func handleCancelUploads() {
        // Cancel all pending uploads
        for fileInfo in state.uploadingFiles {
            coordinator?.didCancelUpload(fileInfo)
        }
        state.dismissCancelUploadsAlert()
    }
    
    /// Filters files based on search text
    private func filterFiles(searchText: String) {
        guard !searchText.isEmpty else {
            // Reset to show all files
            state.syncFromViewModel()
            return
        }
        
        // Filter files by name (case-insensitive)
        let lowercasedSearch = searchText.lowercased()
        let filteredFiles = state.files.filter { file in
            file.name.lowercased().contains(lowercasedSearch)
        }
        
        state.updateFiles(filteredFiles)
    }
    
    // MARK: - Permission Checks
    
    /// Checks photo library permission
    private func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        default:
            completion(false)
        }
    }
    
    /// Checks camera permission
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        default:
            completion(false)
        }
    }
}

// MARK: - FileModel + Identifiable

extension FileModel: Identifiable {
    public var id: Int { folderLinkId }
}

// MARK: - SwiftUIMainView Modifiers

@available(iOS 17, *)
extension SwiftUIMainView {
    
    /// Sets the coordinator for handling file list actions
    func coordinator(_ coordinator: EnhancedFileListCoordinatorProtocol?) -> SwiftUIMainView {
        var view = self
        view.coordinator = coordinator
        return view
    }
    
    /// Sets the callback for photos selection
    func onPhotosSelected(_ action: @escaping ([PhotosPickerItem]) -> Void) -> SwiftUIMainView {
        var view = self
        view.onPhotosSelected = action
        return view
    }
    
    /// Sets the callback for documents selection
    func onDocumentsSelected(_ action: @escaping ([URL]) -> Void) -> SwiftUIMainView {
        var view = self
        view.onDocumentsSelected = action
        return view
    }
    
    /// Sets the callback for camera image capture
    func onImageCaptured(_ action: @escaping (UIImage) -> Void) -> SwiftUIMainView {
        var view = self
        view.onImageCaptured = action
        return view
    }
    
    /// Sets the callback for camera video capture
    func onVideoCaptured(_ action: @escaping (URL) -> Void) -> SwiftUIMainView {
        var view = self
        view.onVideoCaptured = action
        return view
    }
    
    /// Sets the callback for move action
    func onMoveAction(_ action: @escaping () -> Void) -> SwiftUIMainView {
        var view = self
        view.onMoveAction = action
        return view
    }
    
    /// Sets the callback for copy action
    func onCopyAction(_ action: @escaping () -> Void) -> SwiftUIMainView {
        var view = self
        view.onCopyAction = action
        return view
    }
    
    /// Sets the callback for share action
    func onShareAction(_ action: @escaping () -> Void) -> SwiftUIMainView {
        var view = self
        view.onShareAction = action
        return view
    }
    
    /// Sets the callback for download action
    func onDownloadAction(_ action: @escaping () -> Void) -> SwiftUIMainView {
        var view = self
        view.onDownloadAction = action
        return view
    }
}

// MARK: - Toast View (for toast overlay)

@available(iOS 17, *)
struct ToastView: View {
    let message: String
    let type: ToastType
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.custom("Usual-Regular", size: 14))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(type.backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

@available(iOS 17, *)
#Preview {
    // Note: Preview requires a mock FilesViewModel
    // In production, use MyFilesViewModel or PublicFilesViewModel
    Text("SwiftUIMainView Preview")
        .font(.title)
        .foregroundColor(.secondary)
}
