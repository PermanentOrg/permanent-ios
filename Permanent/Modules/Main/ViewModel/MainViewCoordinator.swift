//
//  MainViewCoordinator.swift
//  Permanent
//
//  Created on 19.12.2025.
//  Phase 5 Part 5: Coordinator for handling file actions
//

import Foundation
import SwiftUI
import PhotosUI

// MARK: - MainViewCoordinatorProtocol

/// Protocol defining the actions that can be performed on files
@available(iOS 17, *)
@MainActor
protocol MainViewCoordinatorProtocol: AnyObject {
    // MARK: - File Actions
    
    /// Downloads the specified files
    /// - Parameter files: The files to download
    func downloadFiles(_ files: [FileModel])
    
    /// Shares the specified files
    /// - Parameter files: The files to share
    func shareFiles(_ files: [FileModel])
    
    /// Initiates move operation for the specified files
    /// - Parameter files: The files to move
    func moveFiles(_ files: [FileModel])
    
    /// Initiates copy operation for the specified files
    /// - Parameter files: The files to copy
    func copyFiles(_ files: [FileModel])
    
    /// Deletes the specified files
    /// - Parameter files: The files to delete
    func deleteFiles(_ files: [FileModel])
    
    /// Renames a single file
    /// - Parameter file: The file to rename
    func renameFile(_ file: FileModel)
    
    // MARK: - Upload Actions
    
    /// Uploads photos selected from the photo picker
    /// - Parameter items: The selected photo picker items
    func uploadPhotos(_ items: [PhotosPickerItem])
    
    /// Uploads documents from the specified URLs
    /// - Parameter urls: The URLs of the documents to upload
    func uploadDocuments(_ urls: [URL])
    
    /// Uploads a captured image from the camera
    /// - Parameter image: The captured image
    func uploadCapturedImage(_ image: UIImage)
    
    /// Uploads a captured video from the camera
    /// - Parameter url: The URL of the captured video
    func uploadCapturedVideo(_ url: URL)
    
    // MARK: - Navigation
    
    /// Opens the file preview for a file
    /// - Parameter file: The file to preview
    func openFilePreview(_ file: FileModel)
    
    /// Opens the metadata editor for a file
    /// - Parameter file: The file to edit metadata for
    func openEditMetadata(_ file: FileModel)
    
    /// Opens the share management view for a file
    /// - Parameter file: The file to manage sharing for
    func openShareManagement(_ file: FileModel)
}

// MARK: - MainViewCoordinator

/// Coordinator that handles file actions by delegating to FilesViewModel
/// and updating MainViewState accordingly
@available(iOS 17, *)
@MainActor
class MainViewCoordinator: MainViewCoordinatorProtocol {
    
    // MARK: - Properties
    
    /// Reference to the underlying FilesViewModel
    weak var viewModel: FilesViewModel?
    
    /// Reference to the MainViewState for UI updates
    weak var state: MainViewState?
    
    /// Delegate for navigation actions that require UIKit
    weak var navigationDelegate: MainViewCoordinatorNavigationDelegate?
    
    // MARK: - Initialization
    
    /// Creates a new MainViewCoordinator
    /// - Parameters:
    ///   - viewModel: The FilesViewModel to delegate actions to
    ///   - state: The MainViewState for UI updates
    init(viewModel: FilesViewModel?, state: MainViewState?) {
        self.viewModel = viewModel
        self.state = state
    }
    
    // MARK: - File Actions
    
    func downloadFiles(_ files: [FileModel]) {
        guard !files.isEmpty else {
            state?.showToast(message: "No files selected for download", type: .info)
            return
        }
        
        guard let viewModel = viewModel else {
            state?.showToast(message: "Download unavailable", type: .error)
            return
        }
        
        // Start downloads sequentially
        for file in files {
            // Skip folders - they can't be downloaded directly
            guard !file.type.isFolder else {
                continue
            }
            
            viewModel.download(
                file,
                onDownloadStart: { [weak self] in
                    self?.state?.syncFromViewModel()
                },
                onFileDownloaded: { [weak self] downloadURL, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.state?.showToast(
                            message: "Download failed: \(error.localizedDescription)",
                            type: .error
                        )
                    } else if downloadURL != nil {
                        self.state?.showToast(
                            message: "Downloaded: \(file.name)",
                            type: .success
                        )
                    }
                    
                    self.state?.syncFromViewModel()
                },
                progressHandler: nil
            )
        }
        
        state?.showToast(
            message: "Downloading \(files.count) file(s)...",
            type: .info
        )
    }
    
    func shareFiles(_ files: [FileModel]) {
        guard !files.isEmpty else {
            state?.showToast(message: "No files selected for sharing", type: .info)
            return
        }
        
        // Delegate to navigation delegate for presenting share UI
        navigationDelegate?.presentShareSheet(for: files)
    }
    
    func moveFiles(_ files: [FileModel]) {
        guard !files.isEmpty else {
            state?.showToast(message: "No files selected to move", type: .info)
            return
        }
        
        guard let viewModel = viewModel else {
            state?.showToast(message: "Move unavailable", type: .error)
            return
        }
        
        // Set the file action on the view model
        viewModel.fileAction = .move
        viewModel.selectedFiles = files
        
        // Delegate to navigation delegate for presenting destination picker
        navigationDelegate?.presentDestinationPicker(for: files, action: .move)
    }
    
    func copyFiles(_ files: [FileModel]) {
        guard !files.isEmpty else {
            state?.showToast(message: "No files selected to copy", type: .info)
            return
        }
        
        guard let viewModel = viewModel else {
            state?.showToast(message: "Copy unavailable", type: .error)
            return
        }
        
        // Set the file action on the view model
        viewModel.fileAction = .copy
        viewModel.selectedFiles = files
        
        // Delegate to navigation delegate for presenting destination picker
        navigationDelegate?.presentDestinationPicker(for: files, action: .copy)
    }
    
    func deleteFiles(_ files: [FileModel]) {
        guard !files.isEmpty else {
            state?.showToast(message: "No files selected for deletion", type: .info)
            return
        }
        
        // Present confirmation through state
        state?.presentDeleteConfirmation(for: files)
    }
    
    /// Performs the actual deletion after confirmation
    /// - Parameter files: The files to delete
    func performDelete(_ files: [FileModel]) {
        guard let viewModel = viewModel else {
            state?.showToast(message: "Delete unavailable", type: .error)
            return
        }
        
        state?.setLoading(true)
        
        viewModel.delete(files) { [weak self] status in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.state?.setLoading(false)
                
                switch status {
                case .success:
                    // Remove files from the view model
                    viewModel.removeSyncedFiles(files)
                    self.state?.syncFromViewModel()
                    self.state?.clearSelection()
                    self.state?.showToast(
                        message: "Deleted \(files.count) item(s)",
                        type: .success
                    )
                    
                case .error(let message):
                    self.state?.showToast(
                        message: message ?? "Failed to delete files",
                        type: .error
                    )
                }
            }
        }
    }
    
    func renameFile(_ file: FileModel) {
        // Delegate to navigation delegate for presenting rename dialog
        navigationDelegate?.presentRenameDialog(for: file)
    }
    
    // MARK: - Upload Actions
    
    func uploadPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        
        guard let currentFolder = state?.currentFolder else {
            state?.showToast(message: "No folder selected for upload", type: .error)
            return
        }
        
        state?.setLoading(true)
        
        Task {
            var fileInfos: [FileInfo] = []
            
            for item in items {
                // Load transferable data from PhotosPickerItem
                if let data = try? await item.loadTransferable(type: Data.self) {
                    // Create a temporary file with proper extension
                    let fileName = "photo_\(UUID().uuidString).jpg"
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                    
                    do {
                        try data.write(to: tempURL)
                        let folderInfo = FolderInfo(
                            folderId: currentFolder.folderId,
                            folderLinkId: currentFolder.folderLinkId
                        )
                        let fileInfo = FileInfo(
                            withURL: tempURL,
                            named: fileName,
                            folder: folderInfo
                        )
                        fileInfos.append(fileInfo)
                    } catch {
                        // Continue with other files
                        continue
                    }
                }
            }
            
            await MainActor.run {
                state?.setLoading(false)
                
                if !fileInfos.isEmpty {
                    viewModel?.uploadFiles(fileInfos)
                    state?.syncFromViewModel()
                    state?.showToast(
                        message: "Uploading \(fileInfos.count) photo(s)...",
                        type: .info
                    )
                } else {
                    state?.showToast(
                        message: "Failed to prepare photos for upload",
                        type: .error
                    )
                }
            }
        }
    }
    
    func uploadDocuments(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        
        guard let currentFolder = state?.currentFolder else {
            state?.showToast(message: "No folder selected for upload", type: .error)
            return
        }
        
        let folderInfo = FolderInfo(
            folderId: currentFolder.folderId,
            folderLinkId: currentFolder.folderLinkId
        )
        
        var fileInfos: [FileInfo] = []
        
        for url in urls {
            // Start accessing security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                // Copy file to app's temporary directory
                let tempURL = try FileHelper().copyFile(withURL: url, name: url.lastPathComponent)
                let fileInfo = FileInfo(
                    withURL: tempURL,
                    named: url.lastPathComponent,
                    folder: folderInfo
                )
                fileInfos.append(fileInfo)
            } catch {
                // Continue with other files
                continue
            }
        }
        
        if !fileInfos.isEmpty {
            viewModel?.uploadFiles(fileInfos)
            state?.syncFromViewModel()
            state?.showToast(
                message: "Uploading \(fileInfos.count) document(s)...",
                type: .info
            )
        } else {
            state?.showToast(
                message: "Failed to prepare documents for upload",
                type: .error
            )
        }
    }
    
    func uploadCapturedImage(_ image: UIImage) {
        guard let currentFolder = state?.currentFolder else {
            state?.showToast(message: "No folder selected for upload", type: .error)
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            state?.showToast(message: "Failed to process captured image", type: .error)
            return
        }
        
        let fileName = "capture_\(Date().timeIntervalSince1970).jpg"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: tempURL)
            
            let folderInfo = FolderInfo(
                folderId: currentFolder.folderId,
                folderLinkId: currentFolder.folderLinkId
            )
            
            let fileInfo = FileInfo(
                withURL: tempURL,
                named: fileName,
                folder: folderInfo
            )
            
            viewModel?.uploadFiles([fileInfo])
            state?.syncFromViewModel()
            state?.showToast(message: "Uploading captured image...", type: .info)
        } catch {
            state?.showToast(
                message: "Failed to save captured image: \(error.localizedDescription)",
                type: .error
            )
        }
    }
    
    func uploadCapturedVideo(_ url: URL) {
        guard let currentFolder = state?.currentFolder else {
            state?.showToast(message: "No folder selected for upload", type: .error)
            return
        }
        
        do {
            // Copy video to app's temporary directory
            let tempURL = try FileHelper().copyFile(withURL: url, name: url.lastPathComponent)
            
            let folderInfo = FolderInfo(
                folderId: currentFolder.folderId,
                folderLinkId: currentFolder.folderLinkId
            )
            
            let fileInfo = FileInfo(
                withURL: tempURL,
                named: url.lastPathComponent,
                folder: folderInfo
            )
            
            viewModel?.uploadFiles([fileInfo])
            state?.syncFromViewModel()
            state?.showToast(message: "Uploading captured video...", type: .info)
        } catch {
            state?.showToast(
                message: "Failed to prepare video for upload: \(error.localizedDescription)",
                type: .error
            )
        }
    }
    
    // MARK: - Navigation
    
    func openFilePreview(_ file: FileModel) {
        // Delegate to navigation delegate for UIKit presentation
        navigationDelegate?.presentFilePreview(for: file)
    }
    
    func openEditMetadata(_ file: FileModel) {
        navigationDelegate?.presentMetadataEditor(for: file)
    }
    
    func openShareManagement(_ file: FileModel) {
        navigationDelegate?.presentShareManagement(for: file)
    }
    
    // MARK: - Relocation Handling
    
    /// Performs the relocation (move/copy) to the selected destination
    /// - Parameters:
    ///   - files: The files to relocate
    ///   - destination: The destination folder
    func performRelocation(_ files: [FileModel], to destination: FileModel) {
        guard let viewModel = viewModel else {
            state?.showToast(message: "Operation unavailable", type: .error)
            return
        }
        
        let action = viewModel.fileAction
        state?.setLoading(true)
        
        viewModel.relocate(files: files, to: destination) { [weak self] status in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.state?.setLoading(false)
                
                switch status {
                case .success:
                    // If moving, remove from current folder
                    if action == .move {
                        viewModel.removeSyncedFiles(files)
                    }
                    
                    self.state?.syncFromViewModel()
                    self.state?.clearSelection()
                    
                    let actionVerb = action == .move ? "Moved" : "Copied"
                    self.state?.showToast(
                        message: "\(actionVerb) \(files.count) item(s)",
                        type: .success
                    )
                    
                case .error(let message):
                    let actionVerb = action == .move ? "move" : "copy"
                    self.state?.showToast(
                        message: message ?? "Failed to \(actionVerb) files",
                        type: .error
                    )
                }
            }
        }
    }
}

// MARK: - Navigation Delegate Protocol

/// Protocol for navigation actions that require UIKit presentation
@available(iOS 17, *)
@MainActor
protocol MainViewCoordinatorNavigationDelegate: AnyObject {
    /// Presents a share sheet for the specified files
    func presentShareSheet(for files: [FileModel])
    
    /// Presents a destination picker for move/copy operations
    func presentDestinationPicker(for files: [FileModel], action: FileAction)
    
    /// Presents a rename dialog for a file
    func presentRenameDialog(for file: FileModel)
    
    /// Presents the file preview for a file
    func presentFilePreview(for file: FileModel)
    
    /// Presents the metadata editor for a file
    func presentMetadataEditor(for file: FileModel)
    
    /// Presents the share management view for a file
    func presentShareManagement(for file: FileModel)
}
