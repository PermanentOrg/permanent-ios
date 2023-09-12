//
//  TagsLocalDataSource.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.10.2022.
//

import Foundation

class TagsLocalDataSource: ViewModelInterface {
    static let shared = TagsLocalDataSource()
    var allTags: Dictionary<Int, [TagVO]> = [:]
    
    func getTagsByArchive() -> [TagVO] {
        let archiveId: Int = AuthenticationManager.shared.session?.selectedArchive?.archiveID ?? 0
        return allTags[archiveId] ?? []
    }
    
    func addTags(tags: [TagVO], completion: @escaping (([TagVO]?, Error?) -> Void)) {
        let archiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID ?? 0
        self.allTags[archiveId] = tags
        completion(tags, nil)
    }
    
    func assignTags(tags: [TagLinkVO], completion: @escaping (([TagLinkVO]?, Error?) -> Void)) {
        completion(tags, nil)
    }
    
    func addTagToArchiveOnly(tags: [TagVO], completion: @escaping (([TagVO]?, Error?) -> Void)) {
        let archiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID ?? 0
        self.allTags[archiveId] = tags
        completion(tags, nil)
    }
    
    func unassignTags(tagVOs: [TagVO], recordId: Int, completion: @escaping ((Error?, String?) -> Void)) {
        completion(nil, nil)
    }
    
    func deleteTags(tagVOs: [TagVO], completion: @escaping ((Error?, String?) -> Void)) {
        let archiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID ?? 0
        var tags = allTags[archiveId]
        tags?.removeAll(where: { tag in
            tagVOs.contains(tag)
        })
        allTags[archiveId] = tags
        completion(nil, nil)
    }
    
    func updateTag(tagVO: TagVO, newTagName: String, completion: @escaping ((Error?) -> Void)) {
        let archiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID ?? 0
        var tags = allTags[archiveId]
        var editedTag = tags?.first(where: {$0.tagVO.tagId == tagVO.tagVO.tagId})
        tags?.removeAll(where: {$0.tagVO.tagId == tagVO.tagVO.tagId})
        editedTag?.tagVO.name = newTagName
        if let editedTag = editedTag { tags?.append(editedTag) }
        allTags[archiveId] = tags
        completion(nil)
    }
}
