//
//  SaveDestinationBrowserViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 18.10.2022.
//

import Foundation

class SaveDestinationBrowserViewModel: FileBrowserViewModel {
    enum Workspace {
        case privateFiles
        case sharedFiles
        case publicFiles
    }
    
    var workspace: Workspace = .privateFiles
    
    var hasSaveButton: Bool {
        return workspace == .sharedFiles ? self.contentViewModels.count > 1 : true
    }
    
    init(workspace: Workspace, filesRepository: FilesRepository = FilesRepository(), session: PermSession? = PermSession.currentSession) {
        self.workspace = workspace
        
        super.init(navigationViewModel: ShareFolderNavigationViewModel(workspaceName: ""), filesRepository: filesRepository, session: session)
        
        navigationViewModel.workspaceName = "Private Files"
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
        case .sharedFiles:
            navigationViewModel.workspaceName = "Shared Files"
            
            filesRepository.getSharedRoot { rootFolder, error in
                if let rootFolder = rootFolder {
                    self.contentViewModels.removeAll()
                    self.contentViewModels.append(FolderContentViewModel(folder: rootFolder))
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

    func hasPublicFilesPermission() -> Bool {
        let archive = session.selectedArchive
        return archive.permissions().contains(.archiveShare)
    }
}
