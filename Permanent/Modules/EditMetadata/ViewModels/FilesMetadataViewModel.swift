//
//  FilesMetadataViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.06.2023.

import Foundation

class FilesMetadataViewModel: ObservableObject {
    @Published var selectedFiles: [FileViewModel] = []
    
    init(files: [FileViewModel]) {
        self.selectedFiles = files
    }
    
    func saveDescription(_ text: String) {
        ///To do:  add  new description text
    }
}
