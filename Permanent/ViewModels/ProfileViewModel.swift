//
//  ProfilePageViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.11.2021.
//

import UIKit

class ProfilePageViewModel: ViewModelInterface {
    var archiveData: ArchiveVOData?
    var archiveTitle: String?
    
    init(authData: AuthViewModel) {
        guard let archiveData = authData.getCurrentArchive() else { return }
        self.archiveData = archiveData
        self.archiveTitle = archiveData.fullName
    }
}
