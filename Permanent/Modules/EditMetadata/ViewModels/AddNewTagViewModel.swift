//
//  AddNewTagViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.07.2023.

import Foundation

class AddNewTagViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var allTags: [TagVO] = []
    @Published var selectionTags: [TagVO] = []
    
    let tagsRepository: TagsRepository
    
    init(tagsRepository: TagsRepository = TagsRepository(), selectionTags: [TagVO]) {
        self.tagsRepository = tagsRepository
        self.selectionTags = selectionTags
    }
    
    func refreshTags() {
        isLoading = true
        guard let archiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID else { return }
        allTags = tagsRepository.getTagsByArchive(archiveId: archiveId) { tags, error in
            self.isLoading = false
            self.allTags = tags ?? []
        } ?? []
    }
}
