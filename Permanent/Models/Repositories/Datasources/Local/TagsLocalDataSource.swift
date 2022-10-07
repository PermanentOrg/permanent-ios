//
//  TagsLocalDataSource.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.10.2022.
//

import Foundation

class TagsLocalDataSource: ViewModelInterface {
    static let shared = TagsLocalDataSource()
    var tags: [TagVO] = []
    
    func getTagsByArchive() -> [TagVO] {
        return tags
    }
    
    func addTags(tags: [TagVO], completion: @escaping (([TagVO]?, Error?) -> Void)) {
        self.tags = tags
        completion(tags, nil)
    }
    
    func assignTags(tags: [TagLinkVO], completion: @escaping (([TagLinkVO]?, Error?) -> Void)) {
        completion(tags, nil)
    }
    
    func unassignTags(tagVO: [TagVO], recordId: Int, completion: @escaping ((Error?, String?) -> Void)) {
        completion(nil, nil)
    }
    
    func deleteTags(tagVO: [TagVO], completion: @escaping ((Error?, String?) -> Void)) {
        completion(nil, nil)
    }
}
