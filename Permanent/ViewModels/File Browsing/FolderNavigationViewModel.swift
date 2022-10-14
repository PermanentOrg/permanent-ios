//
//  FolderNavigationViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 14.10.2022.
//

import Foundation

class FolderNavigationViewModel: ViewModelInterface {
    static let didUpdateFolderStackNotification = Notification.Name("FolderNavigationViewModel.didUpdateFolderStackNotification")
    
    var workspaceName: String
    var folderStack: [FileViewModel] = [] {
        didSet {
            NotificationCenter.default.post(name: Self.didUpdateFolderStackNotification, object: self, userInfo: nil)
        }
    }
    
    var displayName: String {
        if let folder = folderStack.last {
            return folder.name
        }
        
        return workspaceName
    }
    
    var hasBackButton: Bool {
        folderStack.isEmpty == false
    }
    
    init(workspaceName: String) {
        self.workspaceName = workspaceName
    }
    
    func pushFolder(_ folder: FileViewModel) {
        folderStack.append(folder)
    }
    
    func popFolder() {
        guard folderStack.isEmpty == false else { return }
        
        _ = folderStack.popLast()
    }
    
    func popToFolder(_ folder: FileViewModel) {
        var newStack = folderStack
        
        while newStack.last != folder {
            _ = newStack.popLast()
        }
        
        folderStack = newStack
    }
}
