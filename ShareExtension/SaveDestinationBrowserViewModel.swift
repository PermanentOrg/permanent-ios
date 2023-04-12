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
                if let rootFolder = rootFolder {
                    self.contentViewModels.removeAll()
                    self.contentViewModels.append(FolderContentViewModel(folder: rootFolder))
                }
            }
            
        case .sharedByMeFiles:
            navigationViewModel.workspaceName = "Shared Files"
            
            filesRepository.getSharedRoot() { rootFolder, error in
                if let rootFolder = rootFolder {
                    self.contentViewModels.removeAll()
                    self.contentViewModels.append(FolderContentViewModel(folder: rootFolder, byMe: true))
                }
            }
            
        case .shareWithMeFiles:
            navigationViewModel.workspaceName = "Shared Files"
            
            filesRepository.getSharedRoot() { rootFolder, error in
                if let rootFolder = rootFolder {
                    self.contentViewModels.removeAll()
                    self.contentViewModels.append(FolderContentViewModel(folder: rootFolder, byMe: false))
                }
            }
            
        case .publicFiles:
            navigationViewModel.workspaceName = "Public Files"
            
            filesRepository.getPublicRoot { rootFolder, error in
                if let rootFolder = rootFolder {
                    self.contentViewModels.removeAll()
                    self.contentViewModels.append(FolderContentViewModel(folder: rootFolder))
                }
            }
        }
    }
    
    func selectedFolder() -> FileViewModel? {
        return contentViewModels.last?.folder
    }
    
    func selectedFolderInfo() -> FolderInfo? {
        guard let selectedFolder = selectedFolder() else { return nil }
        return FolderInfo(folderId: selectedFolder.folderId, folderLinkId: selectedFolder.folderLinkId)
    }
}
