//
//  FolderContentViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 14.10.2022.
//

import Foundation

class FolderContentViewModel: ViewModelInterface {
    static let didUpdateFilesNotification = Notification.Name("FolderContentViewModel.didUpdateFilesNotification")
    
    let folder: FileViewModel
    let filesRepository: FilesRepository
    
    var files: [FileViewModel] = [] {
        didSet {
            NotificationCenter.default.post(name: Self.didUpdateFilesNotification, object: self, userInfo: nil)
        }
    }
    
    init(folder: FileViewModel, filesRepository: FilesRepository = FilesRepository()) {
        self.folder = folder
        self.filesRepository = filesRepository
        
        refreshFolder()
    }
    
    func refreshFolder() {
        filesRepository.folderContent(archiveNo: folder.archiveNo, folderLinkId: folder.folderLinkId) { files, error in
            self.files = files
        }
    }
}
