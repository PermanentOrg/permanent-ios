//
//  FilePreviewView.swift
//  Permanent
//
//  Created on 19.12.2025
//  Phase 5 Part 2: SwiftUI wrapper for FilePreviewViewController
//

import SwiftUI
import UIKit

// MARK: - FilePreviewView

/// A SwiftUI wrapper around `FilePreviewViewController` for displaying file previews.
/// Supports images, videos, audio, PDFs, and miscellaneous file types.
@available(iOS 17, *)
struct FilePreviewView: UIViewControllerRepresentable {
    
    // MARK: - Properties
    
    /// The file to preview
    let file: FileModel
    
    /// Callback when the preview is dismissed
    var onDismiss: (() -> Void)?
    
    /// Optional callback for share action
    var onShare: ((FileModel) -> Void)?
    
    /// Optional callback for download action
    var onDownload: ((FileModel) -> Void)?
    
    // MARK: - Coordinator
    
    /// Coordinator for managing UIKit delegate callbacks
    class Coordinator: NSObject {
        var parent: FilePreviewView
        
        init(_ parent: FilePreviewView) {
            self.parent = parent
        }
        
        /// Handles share button tap
        @objc func handleShare(_ sender: Any) {
            parent.onShare?(parent.file)
        }
        
        /// Handles download action
        @objc func handleDownload(_ sender: Any) {
            parent.onDownload?(parent.file)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> FilePreviewViewController {
        // Create the FilePreviewViewController from storyboard
        guard let filePreviewVC = UIViewController.create(
            withIdentifier: .filePreview,
            from: .main
        ) as? FilePreviewViewController else {
            // Fallback: Create a basic instance if storyboard creation fails
            let fallbackVC = FilePreviewViewController()
            fallbackVC.file = file
            return fallbackVC
        }
        
        // Configure the view controller with the file
        filePreviewVC.file = file
        
        // Set up callback for when record is loaded
        filePreviewVC.recordLoadedCB = { [weak filePreviewVC] _ in
            // Record loaded, preview is ready
            // Additional configuration can happen here if needed
        }
        
        return filePreviewVC
    }
    
    func updateUIViewController(_ uiViewController: FilePreviewViewController, context: Context) {
        // Check if file has changed
        if uiViewController.file.folderLinkId != file.folderLinkId {
            uiViewController.file = file
            uiViewController.loadVM()
        }
    }
    
    static func dismantleUIViewController(_ uiViewController: FilePreviewViewController, coordinator: Coordinator) {
        // Clean up resources when the view is removed
        uiViewController.videoPlayer?.player?.pause()
        uiViewController.videoPlayer?.player = nil
        
        // Call dismiss callback
        coordinator.parent.onDismiss?()
    }
}

// MARK: - FilePreviewView Modifiers

@available(iOS 17, *)
extension FilePreviewView {
    
    /// Sets the dismiss callback
    /// - Parameter action: The action to perform when dismissed
    /// - Returns: A modified FilePreviewView
    func onDismiss(_ action: @escaping () -> Void) -> FilePreviewView {
        var view = self
        view.onDismiss = action
        return view
    }
    
    /// Sets the share callback
    /// - Parameter action: The action to perform when share is tapped
    /// - Returns: A modified FilePreviewView
    func onShare(_ action: @escaping (FileModel) -> Void) -> FilePreviewView {
        var view = self
        view.onShare = action
        return view
    }
    
    /// Sets the download callback
    /// - Parameter action: The action to perform when download is tapped
    /// - Returns: A modified FilePreviewView
    func onDownload(_ action: @escaping (FileModel) -> Void) -> FilePreviewView {
        var view = self
        view.onDownload = action
        return view
    }
}

// MARK: - FilePreviewNavigationWrapper

/// A navigation-wrapped version of FilePreviewView for modal presentation
@available(iOS 17, *)
struct FilePreviewNavigationWrapper: View {
    
    /// The file to preview
    let file: FileModel
    
    /// Dismiss action
    @Environment(\.dismiss) private var dismiss
    
    /// Optional callback for share action
    var onShare: ((FileModel) -> Void)?
    
    /// Optional callback for download action
    var onDownload: ((FileModel) -> Void)?
    
    var body: some View {
        NavigationStack {
            FilePreviewView(
                file: file,
                onDismiss: { dismiss() },
                onShare: onShare,
                onDownload: onDownload
            )
            .navigationTitle(file.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(UIColor.darkBlue))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if let onShare {
                            Button {
                                onShare(file)
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }
                        
                        if let onDownload {
                            Button {
                                onDownload(file)
                            } label: {
                                Label("Download", systemImage: "arrow.down.circle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Color(UIColor.darkBlue))
                    }
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
@available(iOS 17, *)
#Preview("File Preview") {
    // Create a mock FileModel for preview
    FilePreviewNavigationWrapper(
        file: FileModel.mockFile(),
        onShare: { _ in },
        onDownload: { _ in }
    )
}
#endif

// MARK: - FileModel Mock Extension (for Previews)

#if DEBUG
extension FileModel {
    /// Creates a mock FileModel for SwiftUI previews
    static func mockFile() -> FileModel {
        // TODO: Fix preview - RecordVO and FolderLinkVOData initialization needs to be updated
        // to match current API signatures
        fatalError("Preview not yet implemented - needs API update")
        
        /*
        // Return a minimal FileModel for preview purposes
        // Actual implementation would require proper initialization
        let mockRecordVO = RecordVOData(
            recordId: 1,
            archiveNbr: "0001",
            displayName: "Sample File.jpg",
            status: "status.generic.ok",
            type: "type.record.image"
        )
        let mockFolderLinkVO = FolderLinkVOData(
            folderLinkId: 1,
            recordId: 1,
            parentFolderLinkId: 0,
            position: 0
        )
        let mock = RecordVO(recordVO: mockRecordVO, folderLinkVO: mockFolderLinkVO)
        return FileModel(model: mock, archiveThumbnailURL: "", permissions: [.read], accessRole: .viewer)
        */
    }
}
#endif
