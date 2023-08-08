//
//  ReplaceFilenameViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.08.2023.

import Foundation
import SwiftUI

class ReplaceFilenameViewModel: ObservableObject, MyProtocol {
    var fileNamePreview: Binding<String?>
    
    @Published var findText: String = ""
    @Published var replaceText: String = ""

    var selectedFiles: [FileModel]
    
    init(selectedFiles: [FileModel], fileNamePreview: Binding<String?>) {
        self.selectedFiles = selectedFiles
        self.fileNamePreview = fileNamePreview
    }

    func getSelectedFiles() -> [FileModel] {
        let filteredFiles = selectedFiles.map { file in
            var newFile = file
            let name = newFile.name
            newFile.name = name.replacingOccurrences(of: findText, with: replaceText)
            return newFile
        }
        
        return filteredFiles
    }

    func updateReplacePreview() {
        let fileName = selectedFiles.first?.name
        fileNamePreview.wrappedValue = fileName?.replacingOccurrences(of: findText, with: replaceText)
    }
}
