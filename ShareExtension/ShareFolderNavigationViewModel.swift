//
//  ShareFolderNavigationViewModel.swift
//  ShareExtension
//
//  Created by Vlad Alexandru Rusu on 10.02.2023.
//

import Foundation

class ShareFolderNavigationViewModel: FolderNavigationViewModel {
    static let didPopToWorkspaceNotification = Notification.Name("ShareFolderNavigationViewModel.didPopToWorkspaceNotification")
    
    override var hasBackButton: Bool {
        true
    }
    
    override func popFolder() {
        if folderStack.isEmpty {
            NotificationCenter.default.post(name: Self.didPopToWorkspaceNotification, object: self, userInfo: nil)
        } else {
            super.popFolder()
        }
    }
}
