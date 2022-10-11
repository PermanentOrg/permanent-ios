//
//  TagsRepository.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.10.2022.
//

import Foundation

class TagsRepository {
    let localDataSource: TagsLocalDataSource
    let remoteDataSource: TagsRemoteDataSourceInterface
    
    init(localDataSource: TagsLocalDataSource = TagsLocalDataSource.shared, remoteDataSource: TagsRemoteDataSourceInterface = TagsRemoteDataSource()) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
    }
    
    func getTagsByArchive(archiveId: Int, completion: @escaping (([TagVO]?, Error?) -> Void)) -> [TagVO]? {
        remoteDataSource.getTagsByArchive(archiveId: archiveId) { tags, error in
            if let tags = tags {
                self.localDataSource.addTags(tags: tags, completion: completion)
            } else {
                completion(nil, error)
            }
        }
        return localDataSource.getTagsByArchive()
    }
    
    func assignTag(tagNames: [String], recordId: Int, completion: @escaping (([TagLinkVO]?, Error?) -> Void)) {
        remoteDataSource.addTag(tagNames: tagNames, recordId: recordId) { tags, error in
            if let tags = tags {
                self.localDataSource.assignTags(tags: tags, completion: completion)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func unassignTag(tagVO: [TagVO], recordId: Int, completion: @escaping ((Error?) -> Void)) {
        remoteDataSource.unassignTag(tagVO: tagVO, recordId: recordId) { error in
            completion(error)
        }
    }
    
    func deleteTag(tagVO: [TagVO], completion: @escaping ((Error?) -> Void)) {
        remoteDataSource.deleteTag(tagVO: tagVO) { error in
            completion(error)
        }
    }
}
