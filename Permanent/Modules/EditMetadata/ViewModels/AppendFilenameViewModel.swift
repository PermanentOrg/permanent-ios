//
//  AppendFilenameViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2023.

import Foundation
import SwiftUI

class AppendFilenameViewModel: ObservableObject, MyProtocol {
    var fileNamePreview: Binding<String?>
    
    @Published var textToAppend: String = ""
    @Published var positionForText: String = ""

    var selectedFiles: [FileModel]
    var whereOptions = [
        PullDownItem(title: "Before name"),
        PullDownItem(title: "After Name")
    ]
    
    @Published var selectedOption: PullDownItem?
    
    init(selectedFiles: [FileModel], fileNamePreview: Binding<String?>) {
        self.selectedFiles = selectedFiles
        self.fileNamePreview = fileNamePreview
        self.selectedOption = whereOptions.first
    }
    
    func getSelectedFiles() -> [FileModel] {
        return []
    }
    
    func updateAppendPreview() {
        let fileName = selectedFiles.first?.name
        let result = fileName?.appending(textToAppend)
        fileNamePreview.wrappedValue = result
    }
}

