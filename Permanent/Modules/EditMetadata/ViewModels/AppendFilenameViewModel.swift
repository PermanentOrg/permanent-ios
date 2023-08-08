//
//  AppendFilenameViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2023.

import Foundation
import SwiftUI

class AppendFilenameViewModel: ObservableObject, MetadataEditFilenamesProtocol {
    var fileNamePreview: Binding<String?>
    
    @Published var textToAppend: String = ""
    @Published var positionForText: String = ""

    var selectedFiles: [FileModel]
    var whereOptions = [
        PullDownItem(title: "Before name"),
        PullDownItem(title: "After Name")
    ]
    
    @Published var selectedOption: PullDownItem? {
        didSet {
            updateAppendPreview()
        }
    }
    
    init(selectedFiles: [FileModel], fileNamePreview: Binding<String?>) {
        self.selectedFiles = selectedFiles
        self.fileNamePreview = fileNamePreview
        self.selectedOption = whereOptions.first
    }
    
    func getSelectedFiles() -> [FileModel] {
        let filteredFiles = selectedFiles.map { file in
            var newFile = file
            let name = newFile.name
            if selectedOption?.title == "Before name" {
                newFile.name = String("\(textToAppend)\(name)")
            } else {
                newFile.name = String("\(name)\(textToAppend)")
            }
            return newFile
        }
        return filteredFiles
    }
    
    func updateAppendPreview() {
        var fileName = selectedFiles.first?.name ?? ""
        
        if selectedOption?.title == "Before name" {
            fileName = String("\(textToAppend)\(fileName)")
        } else {
            fileName = String("\(fileName)\(textToAppend)")
        }
        

        fileNamePreview.wrappedValue = fileName
    }
}

