//
//  FolderContentViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 14.10.2022.
//

import Foundation

class FolderContentViewModel: ViewModelInterface {
    static let didUpdateFilesNotification = Notification.Name("FolderContentViewModel.didUpdateFilesNotification")
    static let didSelectFileNotification = Notification.Name("FolderContentViewModel.didSelectFileNotification")
    
    let session: PermSession!
    let folder: FileModel
    let filesRepository: FilesRepository
    var byMe: Bool = false
    
    var files: [FileModel] = [] {
        didSet {
            NotificationCenter.default.post(name: Self.didUpdateFilesNotification, object: self, userInfo: nil)
        }
    }
    var isLoading: Bool = true
    
    var isGridView: Bool {
        get {
            session.isGridView
        }
    }
    
    init(folder: FileModel, filesRepository: FilesRepository = FilesRepository(), session: PermSession? = PermSession.currentSession, byMe: Bool = false) {
        self.folder = folder
        self.filesRepository = filesRepository
        self.session = session
        self.byMe = byMe
        
        refreshFolder()
    }
    
    func refreshFolder() {
        filesRepository.folderContent(archiveNo: folder.archiveNo, folderLinkId: folder.folderLinkId, byMe: byMe) { files, error in
            self.isLoading = false
            self.files = files
        }
    }
    
    func insertFile(_ file: FileModel) {
        files.insert(file, at: 0)
    }
    
    func numberOfSections() -> Int {
        return 1
    }
    
    func numberOfItems(inSection section: Int) -> Int {
        return files.count
    }
    
    func fileForRow(atIndexPath indexPath: IndexPath) -> FileModel {
        return files[indexPath.row]
    }
    
    func didSelectFile(_ file: FileModel) {
        NotificationCenter.default.post(name: Self.didSelectFileNotification, object: self, userInfo: ["file": file])
    }
}
