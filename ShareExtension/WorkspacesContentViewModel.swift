//
//  WorkspacesContentViewModel.swift
//  ShareExtension
//
//  Created by Vlad Alexandru Rusu on 07.02.2023.
//

import Foundation

class WorkspacesContentViewModel: FolderContentViewModel {
    
    override var files: [FileModel] {
        get {
            let privateFolder = FileModel(name: "Private", recordId: 0, folderLinkId: 0, archiveNbr: "", type: "", permissions: [], thumbnailURL2000: "https://www.jeffbullas.com/wp-content/uploads/2018/05/the-Detailed-Targeting-section-1-768x313.png")
            let sharedFolder = FileModel(name: "Shared", recordId: 0, folderLinkId: 0, archiveNbr: "", type: "", permissions: [], thumbnailURL2000: "https://www.jeffbullas.com/wp-content/uploads/2018/05/the-Detailed-Targeting-section-1-768x313.png")
            let publicFolder = FileModel(name: "Public", recordId: 0, folderLinkId: 0, archiveNbr: "", type: "", permissions: [])
            
            return [privateFolder, sharedFolder, publicFolder]
        }
        
        set {
            
        }
    }
    
    override init(folder: FileModel, filesRepository: FilesRepository = FilesRepository(), session: PermSession? = PermSession.currentSession, byMe: Bool = false) {
        super.init(folder: folder)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isLoading = false
            NotificationCenter.default.post(name: Self.didUpdateFilesNotification, object: self, userInfo: nil)
        }
    }
    
}
