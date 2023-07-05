//
//  FolderNavigationViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 14.10.2022.
//

import Foundation

class FolderNavigationViewModel: ViewModelInterface {
    static let didUpdateFolderStackNotification = Notification.Name("FolderNavigationViewModel.didUpdateFolderStackNotification")
    static let didPopFolderNotification = Notification.Name("FolderNavigationViewModel.didPopFolderNotification")
    static let didChangeSegmentedControlValueNotification = Notification.Name("FolderNavigationViewModel.didChangeSegmentedControlValueNotification")
    
    var workspaceName: String
    var folderStack: [FileModel] = [] {
        didSet {
            NotificationCenter.default.post(name: Self.didUpdateFolderStackNotification, object: self, userInfo: nil)
        }
    }
    
    var workspace: Workspace

    init(workspaceName: String, workspace: Workspace) {
        self.workspaceName = workspaceName
        self.workspace = workspace
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
    
    func pushFolder(_ folder: FileModel) {
        folderStack.append(folder)
    }
    
    func popFolder() {
        guard folderStack.isEmpty == false else { return }
        
        _ = folderStack.popLast()
        
        NotificationCenter.default.post(name: Self.didPopFolderNotification, object: self, userInfo: nil)
    }
    
    func popToFolder(_ folder: FileModel) {
        var newStack = folderStack
        
        while newStack.last != folder {
            _ = newStack.popLast()
        }
        
        folderStack = newStack
    }
}
