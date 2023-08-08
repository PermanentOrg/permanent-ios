//
//  SequenceFilenameViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2023.

import Foundation
import SwiftUI

class SequenceFilenameViewModel: ObservableObject, MyProtocol {
    var fileNamePreview: Binding<String?>
    
    func getSelectedFiles() -> [FileModel] {
        return []
    }
    
    var selectedFiles: [FileModel]
    var filteredFiles: [FileModel] = []
    
    init(selectedFiles: [FileModel], fileNamePreview: Binding<String?>) {
        self.selectedFiles = selectedFiles
        self.fileNamePreview = fileNamePreview
    }
    
    var baseText: String = ""
    @Published var selectedOption: PullDownItem?
}
