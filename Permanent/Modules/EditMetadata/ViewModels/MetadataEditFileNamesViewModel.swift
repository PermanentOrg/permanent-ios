//
//  MetadataEditFileNamesViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.07.2023.

import Foundation

class MetadataEditFileNamesViewModel: ObservableObject {
    var selectedFiles: [FileModel]
    let tagsRepository: TagsRepository
    
    init(tagsRepository: TagsRepository = TagsRepository(), selectedFiles: [FileModel]) {
        self.tagsRepository = tagsRepository
        self.selectedFiles = selectedFiles
    }
}
