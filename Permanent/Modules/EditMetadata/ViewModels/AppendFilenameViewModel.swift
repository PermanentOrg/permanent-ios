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
    
    init(selectedFiles: [FileModel], fileNamePreview: Binding<String?>) {
        self.selectedFiles = selectedFiles
        self.fileNamePreview = fileNamePreview
    }
    
    func getSelectedFiles() -> [FileModel] {
        return []
    }

    enum WhereToAppendText: String {
        case beforeFilename
        case afterFilename
        
        var position: String {
            switch self {
            case .beforeFilename:
                return "Before filename"
            case .afterFilename:
                return "After filename"
            }
        }
    }
    
    func updateAppendPreview() {
        let fileName = selectedFiles.first?.name
        let result = fileName?.appending(textToAppend)
        fileNamePreview.wrappedValue = result
    }
}

