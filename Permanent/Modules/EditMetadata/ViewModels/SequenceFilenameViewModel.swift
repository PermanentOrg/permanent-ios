//
//  SequenceFilenameViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2023.

import Foundation
import SwiftUI

class SequenceFilenameViewModel: ObservableObject, MetadataEditFilenamesProtocol {
    @Published var isSelectingFormat: Bool = false {
        didSet {
            updatePreview()
        }
    }
    @Published var isSelectingWhere: Bool = false {
        didSet {
            updatePreview()
        }
    }
    @Published var isSelectingAdditionalData: Bool = false {
        didSet {
            updatePreview()
        }
    }
    @Published var selectedFormatOptions: PullDownItem? {
        didSet {
            updatePreview()
            if selectedFormatOptions?.title == "Title & Date" {
                selectedAdditionalOption = PullDownItem(title: "Created")
                additionalOptions = [PullDownItem(title: "Created")]
            } else {
                selectedAdditionalOption = PullDownItem(title: "Start from 1")
                additionalOptions = [PullDownItem(title: "Start from 1")]
            }
        }
    }
    @Published var selectedWhereOptions: PullDownItem?
    @Published var selectedAdditionalOption: PullDownItem?
    @Published var baseText: String = ""
    
    var fileNamePreview: Binding<String?>
    var selectedFiles: [FileModel]
    var filteredFiles: [FileModel] = []
    var whereOptions = [
        PullDownItem(title: "Before name"),
        PullDownItem(title: "After name")
    ]
    var formatOptions = [
        PullDownItem(title: "Title & Date"),
        PullDownItem(title: "Numbers")
    ]
    var additionalOptions: [PullDownItem] = []
    var selectionWillUpdate: Bool = false
    
    init(selectedFiles: [FileModel], fileNamePreview: Binding<String?>) {
        self.selectedFiles = selectedFiles
        self.fileNamePreview = fileNamePreview
        
    }
    
    func getSelectedFiles() -> [FileModel] {
        guard baseText.isNotEmpty else {
            return []
        }
        
        var fileNumber = 0
        let filteredFiles = selectedFiles.map { file in
            var newFile = file
            let name = newFile.name
            if selectedFormatOptions?.title == "Numbers" {
                fileNumber += 1
                
                if selectedWhereOptions?.title == "Before name" {
                    newFile.name = String("\(baseText)_\(getZerosToAddString())\(fileNumber)_\(name)")
                } else {
                    newFile.name = String("\(name)_\(baseText)_\(getZerosToAddString())\(fileNumber)")
                }
            } else {
                var file = selectedFiles.first
                var creationDate = selectedFiles.first?.date ?? ""
                
                
                if selectedWhereOptions?.title == "Before name" {
                    newFile.name = String("\(baseText)_\(creationDate)_\(name)")
                } else {
                    newFile.name = String("\(name)_\(baseText)_\(creationDate)")
                }
            }
            return newFile
        }
        return filteredFiles
    }
    
    func updatePreview() {
        var fileName = selectedFiles.first?.name ?? ""
        guard baseText.isNotEmpty else {
            fileNamePreview.wrappedValue = fileName
            return
        }
        
        if selectedFormatOptions?.title == "Numbers" {
            
            if selectedWhereOptions?.title == "Before name" {
                fileName = String("\(baseText)_\(getZerosToAddString())1_\(fileName)")
            } else {
                fileName = String("\(fileName)_\(baseText)_\(getZerosToAddString())1")
            }
        } else {
            var file = selectedFiles.first
            var creationDate = selectedFiles.first?.date ?? ""
            
            if selectedWhereOptions?.title == "Before name" {
                fileName = String("\(baseText)_\(creationDate)_\(fileName)")
            } else {
                fileName = String("\(fileName)_\(baseText)_\(creationDate)")
            }
        }
        fileNamePreview.wrappedValue = fileName
    }
    
    func getZerosToAddString() -> String {
        String(repeating: "0", count: String(selectedFiles.count).count - 1)
    }
}
