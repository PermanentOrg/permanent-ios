//
//  FolderViewSelectionViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 14.10.2022.
//

import Foundation

class FolderViewSelectionViewModel: ViewModelInterface {
    static let didUpdateFolderViewNotification = Notification.Name("FolderViewSelectionViewModel.didUpdateFolderViewNotification")
    
    let session: PermSession!
    
    var isGridView: Bool {
        get {
            session.isGridView
        }
        
        set {
            session.isGridView = newValue
            
            NotificationCenter.default.post(name: Self.didUpdateFolderViewNotification, object: self, userInfo: nil)
        }
    }
    
    init(session: PermSession? = PermSession.currentSession) {
        self.session = session
    }
}
