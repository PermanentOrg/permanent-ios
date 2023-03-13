//
//  FileBrowserViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 14.10.2022.
//

import Foundation

class FileBrowserViewModel: ViewModelInterface {
    static let didUpdateContentViewModels = Notification.Name("FileBrowserViewModel.didUpdateContentViewModels")
    
    let session: PermSession!
    let filesRepository: FilesRepository
    
    let navigationViewModel: FolderNavigationViewModel
    let sortViewModel: FolderSortViewModel = FolderSortViewModel()
    let viewSelectionViewModel: FolderViewSelectionViewModel = FolderViewSelectionViewModel()
    
    var contentViewModels: [FolderContentViewModel] = [] {
        didSet {
            NotificationCenter.default.post(name: Self.didUpdateContentViewModels, object: self)
        }
    }
    
    init(navigationViewModel: FolderNavigationViewModel, filesRepository: FilesRepository = FilesRepository(), session: PermSession? = PermSession.currentSession) {
        self.filesRepository = filesRepository
        self.session = session
        self.navigationViewModel = navigationViewModel
        
        loadRootFolder()
        
        NotificationCenter.default.addObserver(forName: FolderContentViewModel.didSelectFileNotification, object: nil, queue: nil) { [weak self] notif in
            guard let file = notif.userInfo?["file"] as? FileViewModel else { return }
            
            if file.type.isFolder {
                self?.navigateToFolder(file)
            }
        }
        
        NotificationCenter.default.addObserver(forName: FolderNavigationViewModel.didPopFolderNotification, object: nil, queue: nil) { [weak self] notif in
            self?.navigateBack()
        }
    }
    
    func loadRootFolder() {
        fatalError("loadRootFolder() must be implemented in subclasses")
    }
    
    func navigateToFolder(_ folder: FileViewModel) {
        navigationViewModel.pushFolder(folder)
        contentViewModels.append(FolderContentViewModel(folder: folder, session: session))
    }
    
    func navigateBack() {
//        navigationViewModel.popFolder()
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
