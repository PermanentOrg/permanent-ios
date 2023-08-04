//
//  MetadataEditFileNamesViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.07.2023.

import Foundation
import SwiftUI

protocol MyProtocol {
    func getSelectedFiles() -> [FileModel]
    var fileNamePreview: Binding<String?> {get set}
}

class MetadataEditFileNamesViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    var selectedFiles: [FileModel]
    let tagsRepository: TagsRepository
    @Published var imagePreviewURL: String?
    @Published var fileSizePreview: String?
    @Published var fileNamePreview: String?
    
    var currentViewModel: any MyProtocol
    
    init(tagsRepository: TagsRepository = TagsRepository(), selectedFiles: [FileModel]) {
        self.tagsRepository = tagsRepository
        self.selectedFiles = selectedFiles
        
        imagePreviewURL = selectedFiles.first?.thumbnailURL500
        fileNamePreview = selectedFiles.first?.name
        if let size = selectedFiles.first?.size {
            fileSizePreview = size.bytesToReadableForm(useDecimal: true)
        }
    }
    
    func update() {
        let myFiles = currentViewModel.getSelectedFiles()
    }
}
