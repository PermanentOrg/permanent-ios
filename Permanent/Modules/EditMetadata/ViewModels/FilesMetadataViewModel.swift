//
//  FilesMetadataViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.06.2023.

import SwiftUI
import Foundation

protocol GenericViewModelProtocol: ObservableObject {
    var selectedFiles: [FileViewModel] { get set }
}

class FilesMetadataViewModel: GenericViewModelProtocol {
    @Published var selectedFiles: [FileViewModel] = []
    @Published var inputText: String = ""
    @Published var didSaved: Bool = false {
        didSet {
            saveDescription("")
        }
    }
    
    init(files: [FileViewModel]) {
        self.selectedFiles = files
    }

    func saveDescription(_ text: String) {
        ///To do:  add  new description text
    }
}
