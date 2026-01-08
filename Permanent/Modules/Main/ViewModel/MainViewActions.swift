//
//  MainViewActions.swift
//  Permanent
//
//  Created for UIKit-to-SwiftUI Migration - Phase 1
//  Protocol defining all user actions for the Main Files view
//

import Foundation

// MARK: - MainViewActions Protocol

/// Protocol defining all user actions available in the Main Files view.
/// This provides a clean interface for SwiftUI views to trigger business logic
/// without direct knowledge of UIKit view controllers or view models.
@available(iOS 17, *)
@MainActor
protocol MainViewActions: AnyObject {
    
    // MARK: - Navigation Actions
    
    /// Navigate into a folder
    /// - Parameter folder: The folder to navigate into
    func navigateToFolder(_ folder: FileModel)
    
    /// Navigate back to the previous folder in the navigation stack
    func navigateBack()
    
    // MARK: - Data Actions
    
    /// Refresh the current folder contents
    func refresh() async
    
    // MARK: - Selection Actions
    
    /// Select a file
    /// - Parameter file: The file to select
    func selectFile(_ file: FileModel)
    
    /// Deselect a file
    /// - Parameter file: The file to deselect
    func deselectFile(_ file: FileModel)
    
    /// Toggle selection mode on/off
    func toggleSelection()
    
    /// Clear all selected files
    func clearSelection()
    
    /// Select all files in current folder
    func selectAllFiles()
    
    // MARK: - View Options
    
    /// Set the sort option for files
    /// - Parameter option: The sort option to apply
    func setSortOption(_ option: SortOption)
    
    /// Toggle between grid and list view
    func toggleGridView()
    
    // MARK: - File Operations
    
    /// Delete the currently selected files
    func deleteSelectedFiles()
    
    /// Copy the currently selected files
    func copySelectedFiles()
    
    /// Move the currently selected files
    func moveSelectedFiles()
    
    /// Download a specific file
    /// - Parameter file: The file to download
    func downloadFile(_ file: FileModel)
    
    /// Upload files from the given URLs
    /// - Parameter urls: The URLs of files to upload
    func uploadFiles(_ urls: [URL])
}

// MARK: - MainViewActionsDelegate

/// Delegate protocol for handling action results and callbacks
/// Use this when the action handler needs to communicate back to the originator
@available(iOS 17, *)
@MainActor
protocol MainViewActionsDelegate: AnyObject {
    
    /// Called when navigation to a folder completes
    /// - Parameters:
    ///   - folder: The folder that was navigated to
    ///   - success: Whether navigation succeeded
    func didNavigateToFolder(_ folder: FileModel, success: Bool)
    
    /// Called when a refresh operation completes
    /// - Parameter error: Error if refresh failed, nil on success
    func didRefresh(error: Error?)
    
    /// Called when file deletion completes
    /// - Parameters:
    ///   - files: The files that were deleted
    ///   - error: Error if deletion failed, nil on success
    func didDeleteFiles(_ files: [FileModel], error: Error?)
    
    /// Called when file copy/move completes
    /// - Parameters:
    ///   - files: The files that were relocated
    ///   - destination: The destination folder
    ///   - action: Whether it was copy or move
    ///   - error: Error if operation failed, nil on success
    func didRelocateFiles(_ files: [FileModel], to destination: FileModel, action: FileAction, error: Error?)
    
    /// Called when a download completes
    /// - Parameters:
    ///   - file: The file that was downloaded
    ///   - localURL: The local URL where the file was saved
    ///   - error: Error if download failed, nil on success
    func didDownloadFile(_ file: FileModel, localURL: URL?, error: Error?)
    
    /// Called when upload(s) are queued
    /// - Parameters:
    ///   - files: The files that were queued for upload
    ///   - error: Error if queueing failed, nil on success
    func didQueueUploads(_ files: [FileInfo], error: Error?)
}

// MARK: - Extended File Actions

/// Extended actions for more specific file operations
@available(iOS 17, *)
@MainActor
protocol ExtendedFileActions: MainViewActions {
    
    // MARK: - Single File Actions
    
    /// Rename a file
    /// - Parameters:
    ///   - file: The file to rename
    ///   - newName: The new name for the file
    func renameFile(_ file: FileModel, to newName: String) async throws
    
    /// Get info/details for a file
    /// - Parameter file: The file to get info for
    func getFileInfo(_ file: FileModel)
    
    /// Share a file
    /// - Parameter file: The file to share
    func shareFile(_ file: FileModel)
    
    /// Publish a file to public gallery
    /// - Parameter file: The file to publish
    func publishFile(_ file: FileModel) async throws
    
    // MARK: - Folder Actions
    
    /// Create a new folder in the current location
    /// - Parameter name: The name for the new folder
    func createFolder(named name: String) async throws
    
    // MARK: - Batch Actions
    
    /// Publish all selected files to public gallery
    func publishSelectedFiles() async throws
    
    /// Share all selected files
    func shareSelectedFiles()
    
    // MARK: - Upload Actions
    
    /// Cancel an upload that is in progress or queued
    /// - Parameter file: The file info for the upload to cancel
    func cancelUpload(_ file: FileInfo)
    
    /// Retry a failed upload
    /// - Parameter file: The file info for the upload to retry
    func retryUpload(_ file: FileInfo)
    
    // MARK: - Download Actions
    
    /// Cancel an in-progress download
    /// - Parameter file: The file being downloaded
    func cancelDownload(_ file: FileModel)
}

// MARK: - Default Implementations

@available(iOS 17, *)
extension ExtendedFileActions {
    
    /// Default implementation for publishing selected files
    func publishSelectedFiles() async throws {
        // Default: no-op, override in concrete implementation
    }
    
    /// Default implementation for sharing selected files
    func shareSelectedFiles() {
        // Default: no-op, override in concrete implementation
    }
}

// MARK: - Action Context

/// Context information for file actions
struct FileActionContext {
    /// The source folder where the action originated
    let sourceFolder: FileModel?
    
    /// The files involved in the action
    let files: [FileModel]
    
    /// The type of action being performed
    let action: FileAction
    
    /// Optional destination for move/copy operations
    let destination: FileModel?
    
    init(
        sourceFolder: FileModel? = nil,
        files: [FileModel] = [],
        action: FileAction = .none,
        destination: FileModel? = nil
    ) {
        self.sourceFolder = sourceFolder
        self.files = files
        self.action = action
        self.destination = destination
    }
}
