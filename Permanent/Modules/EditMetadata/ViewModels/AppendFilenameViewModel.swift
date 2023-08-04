//
//  AppendFilenameViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2023.

import Foundation
import SwiftUI

class AppendFilenameViewModel: ObservableObject, MyProtocol {
    func getSelectedFiles() -> [FileModel] {
        
    }
    
    var fileNamePreview: Binding<String?>
    
    init(fileNamePreview: Binding<String?>) {
        self.fileNamePreview = fileNamePreview
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
    
    @Published var textToAppend: String = ""
    @Published var positionForText: String = ""
}

