//
//  ChangeDestinationUploadManagerViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.10.2023.

import Foundation

class ChangeDestinationUploadManagerViewModel: ObservableObject {
    @Published var currentArchive: ArchiveVOData?
    
    init(currentArchive: ArchiveVOData?) {
        self.currentArchive = currentArchive
    }
    
    func getCurrentArchiveName() -> String {
        if let currentArchive = currentArchive {
            return currentArchive.fullName ?? ""
        }
        return ""
    }
}
