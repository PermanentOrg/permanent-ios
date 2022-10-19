//
//  SaveDestinationBrowserViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 18.10.2022.
//

import Foundation

class SaveDestinationBrowserViewModel: FileBrowserViewModel {
    override func loadRootFolder() {
        filesRepository.getPrivateRoot { rootFolder, error in
            if let rootFolder = rootFolder {
                self.contentViewModels.append(FolderContentViewModel(folder: rootFolder, session: self.session))
            }
        }
    }
}
