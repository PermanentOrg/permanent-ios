//
//  ManageTagsViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 07.10.2022.
//

import Foundation

class ManageTagsViewModel: ViewModelInterface {
    static let didUpdateTagsNotification = Notification.Name("ManageTagsViewModel.didUpdateTagsNotification")
    
    let tagsRepository: TagsRepository
    var tags: [TagVO] = []
    var sortedTags: [TagVO] = [] {
        didSet {
            NotificationCenter.default.post(name: Self.didUpdateTagsNotification, object: self, userInfo: nil)
        }
    }
    
    init(tagsRepository: TagsRepository = TagsRepository()) {
        self.tagsRepository = tagsRepository
    }
    
    func viewDidLoad() {
        refreshTags()
    }
    
    func refreshTags() {
        guard let archiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID else { return }
        tags = tagsRepository.getTagsByArchive(archiveId: archiveId) { tags, error in
            self.tags = tags ?? []
            self.sortedTags = tags ?? []
        } ?? []
    }
    
    func deleteTag(index: Int, completion: @escaping ((String?) -> Void)) {
        let selectedTag = sortedTags[index]
        
        tagsRepository.deleteTag(tagVO: [selectedTag]) { error in
            if error == nil {
                self.tags.removeAll { tag in
                    tag.tagVO.name == selectedTag.tagVO.name
                }
                self.sortedTags.remove(at: index)
                completion(nil)
            } else {
                completion(error.debugDescription)
            }
        }
    }
}
