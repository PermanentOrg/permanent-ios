//
//  ReplaceFilenameViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.08.2023.

import Foundation

class ReplaceFilenameViewModel: ObservableObject, MyProtocol {
    @Published var findText: String = ""
    @Published var replaceText: String = ""
    
    var selectedFiles: [FileModel]
    
    init(selectedFiles: [FileModel]) {
        self.selectedFiles = selectedFiles
    }
}
