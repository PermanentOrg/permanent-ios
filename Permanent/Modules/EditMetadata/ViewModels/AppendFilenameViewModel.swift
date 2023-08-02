//
//  AppendFilenameViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2023.

import Foundation

class AppendFilenameViewModel: ObservableObject {
    @Published var textToAppend: String = ""
    @Published var positionForText: String = ""
}

enum whereToAppendText: String {
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
