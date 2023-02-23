//
//  ManageTagsViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 07.10.2022.
//

import Foundation

class ManageTagsViewModel: ViewModelInterface {
    static let didUpdateTagsNotification = Notification.Name("ManageTagsViewModel.didUpdateTagsNotification")
    static let isLoadingNotification = Notification.Name("ManageTagsViewModel.isLoadingNotification")
    static let isSearchEnabled = Notification.Name("ManageTagsViewModel.isSearchEnabled")
    static let showBannerNotification = Notification.Name("ManageTagsViewModel.showBannerNotification")
    
    let tagsRepository: TagsRepository
    var tags: [TagVO] = []
    var sortedTags: [TagVO] = [] {
        didSet {
            NotificationCenter.default.post(name: Self.didUpdateTagsNotification, object: self, userInfo: nil)
        }
    }
    var isLoading: Bool = false {
        didSet {
            NotificationCenter.default.post(name: Self.isLoadingNotification, object: self, userInfo: nil)
        }
    }
    var isSearchEnabled: Bool = false {
        didSet {
            NotificationCenter.default.post(name: Self.isSearchEnabled, object: self, userInfo: nil)
        }
    }
    
    init(tagsRepository: TagsRepository = TagsRepository()) {
        self.tagsRepository = tagsRepository
    }
    
    func viewDidLoad() {
        refreshTags()
    }
    
    func refreshTags() {
        isLoading = true
        guard let archiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID else { return }
        tags = tagsRepository.getTagsByArchive(archiveId: archiveId) { tags, error in
            self.isLoading = false
            self.tags = tags ?? []
            self.sortedTags = tags ?? []
        } ?? []
    }
    
    func deleteTag(index: Int, completion: @escaping ((String?) -> Void)) {
        let selectedTag = sortedTags[index]
        isLoading = true
        tagsRepository.deleteTag(tagVO: [selectedTag]) { error in
            self.isLoading = false
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

    func searchTags(withText text: String) {
        if text.isEmpty {
            sortedTags = tags
            isSearchEnabled = false
        } else {
            sortedTags = tags.filter { tag in
                tag.tagVO.name?.lowercased().contains(text.lowercased()) ?? false
            }
            if sortedTags.count != tags.count {
                isSearchEnabled = true
            }
        }
    }
    
    func isNewTagNameValid(withText text: String?) -> Bool {
        if let newTagName = text,
           newTagName.isNotEmpty {
            let filteredTags = tags.filter { tag in
                tag.tagVO.name?.lowercased().contains(newTagName.lowercased()) ?? false
            }
            
            return filteredTags.count == 0
        } else {
            return false
        }
    }
    
    func addTagToArchive(withName tagName: String?, completion: @escaping ((String?) -> Void)) {
        guard let tagName = tagName else {
            completion("error")
            return
        }
        tagsRepository.assignTagToArchive(tagNames: [tagName]) { tags, error in
            if let _ = tags {
                NotificationCenter.default.post(name: Self.showBannerNotification, object: self, userInfo: ["message":"Tag added successfully".localized()])
                self.refreshTags()
                completion(nil)
            } else {
                completion(error.debugDescription)
            }
        }
    }
}
