//
//  MainViewController+FileListCoordinator.swift
//  Permanent
//
//  Created by Copilot on 17/12/2025.
//

import Foundation
import UIKit

/// Extension to bridge SwiftUI FileListView actions to UIKit MainViewController
extension MainViewController: FileListCoordinatorProtocol {
    func didTapFile(_ file: FileItemViewModel) {
        guard let viewModel = viewModel else { return }
        guard let fileModel = viewModel.viewModels.first(where: { $0.recordId == file.id }) else { return }
        
        if fileModel.type.isFolder {
            // Navigate to folder
            viewModel.isSelecting = false
            let navigateParams: NavigateMinParams = (fileModel.archiveNo, fileModel.folderLinkId, nil)
            navigateToFolder(withParams: navigateParams, backNavigation: false, then: {
                self.backButton.isHidden = false
                self.directoryLabel.text = fileModel.name
            })
        } else {
            // Open file preview
            if viewModel.isPickingImage {
                viewModel.pickerDelegate?.myFilesVMDidPickFile(viewModel: viewModel, file: fileModel)
            } else {
                let listPreviewVC = FilePreviewListViewController(nibName: nil, bundle: nil)
                listPreviewVC.modalPresentationStyle = .fullScreen
                listPreviewVC.viewModel = viewModel
                listPreviewVC.currentFile = fileModel
                
                let fileDetailsNavigationController = FilePreviewNavigationController(rootViewController: listPreviewVC)
                fileDetailsNavigationController.filePreviewNavDelegate = self
                fileDetailsNavigationController.modalPresentationStyle = .fullScreen
                
                present(fileDetailsNavigationController, animated: true)
            }
        }
    }
    
    func didTapMore(for file: FileItemViewModel) {
        guard let viewModel = viewModel else { return }
        guard let fileModel = viewModel.viewModels.first(where: { $0.recordId == file.id }) else { return }
        
        // Show more options (copy, move, delete, share, etc.)
        showMoreOptions(for: fileModel)
    }
    
    func didLongPress(_ file: FileItemViewModel) {
        guard let viewModel = viewModel,
              let fileListViewModel = fileListViewModel else { return }
        
        // Enter selection mode
        if !viewModel.isSelecting {
            viewModel.isSelecting = true
            viewModel.selectedFiles = []
            fileListViewModel.enterSelectionMode(with: file.id)
            setupBottomActionSheetForMultipleFiles()
        }
        
        // Toggle selection
        didToggleSelection(file)
    }
    
    func didToggleSelection(_ file: FileItemViewModel) {
        guard let viewModel = viewModel,
              let fileListViewModel = fileListViewModel else { return }
        guard let fileModel = viewModel.viewModels.first(where: { $0.recordId == file.id }) else { return }
        
        // Update UIKit view model
        if let index = viewModel.selectedFiles?.firstIndex(of: fileModel) {
            viewModel.selectedFiles?.remove(at: index)
        } else {
            if viewModel.selectedFiles == nil {
                viewModel.selectedFiles = []
            }
            viewModel.selectedFiles?.append(fileModel)
        }
        
        // Update SwiftUI view model
        fileListViewModel.toggleSelection(for: file.id)
        
        // Update bottom action sheet
        if viewModel.selectedFiles?.isEmpty ?? true {
            viewModel.isSelecting = false
            fileListViewModel.exitSelectionMode()
            setupBottomActionSheet()
        } else {
            setupBottomActionSheetForMultipleFiles()
        }
    }
    
    func didRefresh() async {
        await MainActor.run {
            refreshCurrentFolder()
        }
    }
    
    // MARK: - Helper Methods
    
    private func showMoreOptions(for file: FileModel) {
        // Implement file action menu (share, copy, move, delete, etc.)
        // This would typically show an action sheet or menu
        let alert = UIAlertController(title: file.name, message: nil, preferredStyle: .actionSheet)
        
        if file.permissions.contains(.share) {
            alert.addAction(UIAlertAction(title: "Share", style: .default) { [weak self] _ in
                self?.shareFile(file)
            })
        }
        
        if file.permissions.contains(.move) {
            alert.addAction(UIAlertAction(title: "Move", style: .default) { [weak self] _ in
                self?.moveFile(file)
            })
        }
        
        if file.permissions.contains(.delete) {
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.deleteFile(file)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    private func shareFile(_ file: FileModel) {
        // TODO: Implement share functionality
        print("Share file: \(file.name)")
    }
    
    private func moveFile(_ file: FileModel) {
        // TODO: Implement move functionality
        viewModel?.fileAction = FileAction.move
        viewModel?.selectedFiles = [file]
        print("Move file: \(file.name)")
    }
    
    private func deleteFile(_ file: FileModel) {
        // TODO: Implement delete functionality
        print("Delete file: \(file.name)")
    }
}
