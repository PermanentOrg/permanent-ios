//
//  ProfilePageViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.11.2021.
//

import UIKit

class PublicProfilePageViewModel: ViewModelInterface {
    var archiveData: ArchiveVOData!
    
    init(archiveData: ArchiveVOData) {
        self.archiveData = archiveData
    }
}
