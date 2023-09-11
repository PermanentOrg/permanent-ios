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
    @Published var filteredUncommonTags: [TagVO] = []
    @Published var addedTags: [TagVO] = []
    @Published var showAlert: Bool = false
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
        filteredUncommonTags = uncommonTags
    }
    
    func calculateFilteredUncommonTags(text: String) {
        if text.isNotEmpty {
            filteredUncommonTags = uncommonTags.filter({ $0.tagVO.name?.contains(text) == true })
        } else {
            filteredUncommonTags = uncommonTags
        }
    }
    
    func assignTagToArchive(tagNames: [String], completion: @escaping ((Bool) -> Void)) {
        if !tagNames.allSatisfy({ $0.isNotEmpty }) {
            completion(false)
            showAlert = true
            return
        }

        isLoading = true

        tagsRepository.assignTagToArchive(tagNames: tagNames) { [weak self] tagVOs, error in
            self?.isLoading = false
            if let _ = tagVOs {
                self?.refreshTags(selectionTags: tagNames.first)
                completion(true)
            } else {
                completion(false)
                self?.showAlert = true
            }
        }
    }
    
    //MARK: Assign Tags
    
    func addButtonPressed(completion: @escaping ((Bool) -> Void)) {
        isLoading = true
        selectionTags.append(contentsOf: addedTags)
        
        Task {[weak self] in
            guard let strongSelf = self else { return }
            do {
                let _ = try await strongSelf.selectedFiles.compactMap { file in
                    return (strongSelf.selectionTags, file.recordId)
                }.asyncMap(strongSelf.runAssignTag)
                
                await MainActor.run {
                    completion(true)
                }
            }
            catch {
                await MainActor.run {
                    completion(false)
                    strongSelf.showAlert = true
                }
            }
        }
    }
    
    func runAssignTag(tags: [TagVO], recordId: Int) async throws {
        let tagNames = tags.compactMap { $0.tagVO.name }
        return try await withCheckedThrowingContinuation { continuation in
            tagsRepository.assignTag(tagNames: tagNames, recordId: recordId) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
