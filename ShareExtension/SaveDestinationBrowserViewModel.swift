//
//  SaveDestinationBrowserViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 18.10.2022.
//

import Foundation

class SaveDestinationBrowserViewModel: FileBrowserViewModel {
    var workspace: Workspace = .privateFiles {
        didSet {
            loadRootFolder()
        }
    }
     
    var hasSaveButton: Bool {
        switch workspace {
        case .sharedByMeFiles, .shareWithMeFiles:
            return self.contentViewModels.count > 1
        default:
            return true
        }
    }
    
    init(workspace: Workspace, filesRepository: FilesRepository = FilesRepository(), session: PermSession? = PermSession.currentSession) {
        self.workspace = workspace

        let initialWorkspaceName: String
        switch workspace {
        case .privateFiles: initialWorkspaceName = "Private Files"
        case .sharedByMeFiles, .shareWithMeFiles: initialWorkspaceName = "Shared Files"
        case .publicFiles: initialWorkspaceName = "Public Files"
        }

        super.init(navigationViewModel: FolderNavigationViewModel(workspaceName: initialWorkspaceName, workspace: workspace), filesRepository: filesRepository, session: session)
    }
    
    override func loadRootFolder() {
        switch workspace {
        case .privateFiles:
            navigationViewModel.workspaceName = "Private Files"
            
            filesRepository.getPrivateRoot { rootFolder, error in
                DispatchQueue.main.async {
                    if let rootFolder = rootFolder {
                        self.contentViewModels.removeAll()
                        self.contentViewModels.append(FolderContentViewModel(folder: rootFolder))
                    }
                }
            }
            
        case .sharedByMeFiles:
            navigationViewModel.workspaceName = "Shared Files"
            
            filesRepository.getSharedRoot() { rootFolder, error in
                DispatchQueue.main.async {
                    if let rootFolder = rootFolder {
                        self.contentViewModels.removeAll()
                        self.contentViewModels.append(FolderContentViewModel(folder: rootFolder, byMe: true))
                    }
                }
            }
            
        case .shareWithMeFiles:
            navigationViewModel.workspaceName = "Shared Files"
            
            filesRepository.getSharedRoot() { rootFolder, error in
                DispatchQueue.main.async {
                    if let rootFolder = rootFolder {
                        self.contentViewModels.removeAll()
                        self.contentViewModels.append(FolderContentViewModel(folder: rootFolder, byMe: false))
                    }
                }
            }
            
        case .publicFiles:
            navigationViewModel.workspaceName = "Public Files"
            
            filesRepository.getPublicRoot { rootFolder, error in
                DispatchQueue.main.async {
                    if let rootFolder = rootFolder {
                        self.contentViewModels.removeAll()
                        self.contentViewModels.append(FolderContentViewModel(folder: rootFolder))
                    }
                }
            }
        }
    }
    
    func selectedFolder() -> FileModel? {
        return contentViewModels.last?.folder
    }
    
    /// Whether the chosen destination sits in the Shared workspace. Drives the badge
    /// on the upload Live Activity's folder card.
    var isSharedWorkspace: Bool {
        switch workspace {
        case .sharedByMeFiles, .shareWithMeFiles: return true
        case .privateFiles, .publicFiles: return false
        }
    }

    func selectedFolderInfo() -> FolderInfo? {
        guard let destination = contentViewModels.last else { return nil }
        let folder = destination.folder
        return FolderInfo(
            folderId: folder.folderId,
            folderLinkId: folder.folderLinkId,
            name: folder.name,
            // Only report a count once the listing has actually loaded — an
            // in-flight `files` is empty, and the Live Activity would rather show
            // no count than a wrong one.
            itemCount: destination.isLoading ? nil : destination.files.count,
            isShared: isSharedWorkspace
        )
    }
}
