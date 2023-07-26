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
    @Published var uncommonTags: [TagVO] = []
    @Published var addedTags: [TagVO] = []
    @Published var showAddSingleTagAlert: Bool = false
    var selectedFiles: [FileModel]
    
    let tagsRepository: TagsRepository
    
    init(tagsRepository: TagsRepository = TagsRepository(), selectionTags: [TagVO], selectedFiles: [FileModel]) {
        self.tagsRepository = tagsRepository
        self.selectionTags = selectionTags
        self.selectedFiles = selectedFiles
    }
    
    func refreshTags(selectionTags: String? = nil) {
        guard let archiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID else { return }
        isLoading = true
        allTags = tagsRepository.getTagsByArchive(archiveId: archiveId) { [weak self] tags, error in
            self?.isLoading = false
            self?.allTags = tags ?? []
            self?.addedTags.append(contentsOf: tags?.filter({ $0.tagVO.name == selectionTags }) ?? [])
            self?.calculateUncommonTags()
        } ?? []
    }

    func calculateUncommonTags() {
        let selectionTagNames = selectionTags.map { $0.tagVO.name }
        uncommonTags = allTags.filter({ tag in !selectionTags.contains(tag) })
    }
    
    func addButtonPressed(completion: @escaping ((Bool) -> Void)) {
        isLoading = true
        selectionTags.append(contentsOf: addedTags)
        guard let file = selectedFiles.first else { return }
        
        tagsRepository.assignTag(tagNames: selectionTags.map({$0.tagVO.name ?? ""}), recordId: file.recordId) { [weak self] tags, error in
            self?.isLoading = false
            if let tags = tags {
                completion(true)
            } else {
                completion(false)
                self?.showAddSingleTagAlert = true
            }
        }
        
    }
    
    func addSingleTag(tagNames: [String], completion: @escaping ((Bool) -> Void)) {
        isLoading = true
        
        tagsRepository.assignTagToArchive(tagNames: tagNames) { [weak self] tagVOs, error in
            self?.isLoading = false
            if let tags = tagVOs {
                self?.refreshTags(selectionTags: tagNames.first)
                completion(true)
            } else {
                completion(false)
                self?.showAddSingleTagAlert = true
            }
        }
    }
}
