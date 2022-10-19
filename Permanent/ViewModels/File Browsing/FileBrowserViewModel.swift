//
//  FileBrowserViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 14.10.2022.
//

import Foundation

class FileBrowserViewModel: ViewModelInterface {
    let session: PermSession!
    let filesRepository: FilesRepository
    
    let navigationViewModel: FolderNavigationViewModel = FolderNavigationViewModel(workspaceName: "")
    let sortViewModel: FolderSortViewModel = FolderSortViewModel()
    let viewSelectionViewModel: FolderViewSelectionViewModel = FolderViewSelectionViewModel()
    
    var contentViewModels: [FolderContentViewModel] = []
    
    init(filesRepository: FilesRepository = FilesRepository(), session: PermSession? = PermSession.currentSession) {
        self.filesRepository = filesRepository
        self.session = session
        
        loadRootFolder()
    }
    
    func loadRootFolder() {
        fatalError("loadRootFolder() must be implemented in subclasses")
    }
    
    func navigateToFolder(_ folder: FileViewModel) {
        navigationViewModel.pushFolder(folder)
        contentViewModels.append(FolderContentViewModel(folder: folder, session: session))
    }
    
    func navigateBack() {
        navigationViewModel.popFolder()
        _ = contentViewModels.popLast()
    }
    
    func createFolder(named name: String) {
        let folderLinkId = navigationViewModel.folderStack.last?.folderLinkId ?? 0
        filesRepository.createNewFolder(name: name, folderLinkId: folderLinkId) { folder, error in
            if let folder = folder {
                self.contentViewModels.last?.insertFile(folder)
            }
        }
    }
    
    func uploadFiles(_ files: [FileViewModel]) {
        
    }
    
    func downloadFile(_ file: FileViewModel) {
        
    }
    
}
