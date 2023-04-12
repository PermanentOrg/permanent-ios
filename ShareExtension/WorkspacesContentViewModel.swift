//
//  WorkspacesContentViewModel.swift
//  ShareExtension
//
//  Created by Vlad Alexandru Rusu on 07.02.2023.
//

import Foundation

class WorkspacesContentViewModel: FolderContentViewModel {
    
    override var files: [FileViewModel] {
        get {
            let privateFolder = FileViewModel(name: "Private", recordId: 0, folderLinkId: 0, archiveNbr: "", type: "", permissions: [], thumbnailURL2000: "https://www.jeffbullas.com/wp-content/uploads/2018/05/the-Detailed-Targeting-section-1-768x313.png")
            let sharedFolder = FileViewModel(name: "Shared", recordId: 0, folderLinkId: 0, archiveNbr: "", type: "", permissions: [], thumbnailURL2000: "https://www.jeffbullas.com/wp-content/uploads/2018/05/the-Detailed-Targeting-section-1-768x313.png")
            let publicFolder = FileViewModel(name: "Public", recordId: 0, folderLinkId: 0, archiveNbr: "", type: "", permissions: [])
            
            return [privateFolder, sharedFolder, publicFolder]
        }
        
        set {
            
        }
    }
    
    override init(folder: FileViewModel, filesRepository: FilesRepository = FilesRepository(), session: PermSession? = PermSession.currentSession, byMe: Bool = false) {
        super.init(folder: folder)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isLoading = false
            NotificationCenter.default.post(name: Self.didUpdateFilesNotification, object: self, userInfo: nil)
        }
    }
    
}
