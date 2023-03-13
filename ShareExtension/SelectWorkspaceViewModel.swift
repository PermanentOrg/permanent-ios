//
//  SelectWorkspaceViewModel.swift
//  ShareExtension
//
//  Created by Vlad Alexandru Rusu on 07.03.2023.
//

import Foundation

class SelectWorkspaceViewModel: ViewModelInterface {
    let session: PermSession!
    
    init(session: PermSession? = PermSession.currentSession) {
        self.session = session
    }
    
    func hasPublicFilesPermission() -> Bool {
        let archive = session.selectedArchive
        return archive?.permissions().contains(.archiveShare) ?? false
    }
}
