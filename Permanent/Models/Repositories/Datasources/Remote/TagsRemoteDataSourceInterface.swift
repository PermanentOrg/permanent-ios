//
//  TagsRemoteDataSource.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.10.2022.
//

import Foundation
protocol TagsRemoteDataSourceInterface {
    func getTagsByArchive(archiveId: Int, completion: @escaping (([TagVO]?, Error?) -> Void))
    func addTag(tagNames: [String], recordId: Int, completion: @escaping (([TagLinkVO]?, Error?) -> Void))
    func addTagToArchiveOnly(tagNames: [String], completion: @escaping (([TagVO]?, Error?) -> Void))
    func unassignTag(tagVO: [TagVO], recordId: Int, completion: @escaping ((Error?) -> Void))
    func deleteTag(tagVO: [TagVO], completion: @escaping ((Error?) -> Void))
    func updateTag(tagVO: TagVO, newTagName: String, completion: @escaping ((Error?) -> Void))
}

class TagsRemoteDataSource: TagsRemoteDataSourceInterface {
    func getTagsByArchive(archiveId: Int, completion: @escaping (([TagVO]?, Error?) -> Void)) {
        let params: GetTagsByArchiveParams = (archiveId)
        let apiOperation = APIOperation(TagEndpoint.getByArchive(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let json, _):
                guard let model: APIResults<TagVO> = JSONHelper.decoding(from: json, with: APIResults<TagVO>.decoder), model.isSuccessful else {
                    completion(nil, APIError.clientError)
                    return
                }
                let tagVO: [TagVO]? =  model.results.first?.data
                completion(tagVO, nil)
                
            case .error(let errror, _):
                completion(nil, errror)
                
            default:
                completion(nil, APIError.clientError)
            }
        }
    }
    
    func addTag(tagNames: [String], recordId: Int, completion: @escaping (([TagLinkVO]?, Error?) -> Void)) {
        let params: TagParams = (tagNames, recordId)
        let apiOperation = APIOperation(TagEndpoint.post(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let json, _):
                guard let model: APIResults<TagLinkVO> = JSONHelper.decoding(from: json, with: APIResults<TagLinkVO>.decoder), model.isSuccessful else {
                    completion(nil, APIError.clientError)
                    return
                }
                let tagLinkVOs: [TagLinkVO]? =  model.results.compactMap { result in
                    return result.data?.first
                }
                completion(tagLinkVOs, nil)
                
            case .error(let error, _):
                completion(nil, error)
                
            default:
                completion(nil, APIError.clientError)
            }
        }
    }
    
    func addTagToArchiveOnly(tagNames: [String], completion: @escaping (([TagVO]?, Error?) -> Void)) {
        let params: TagParams = (tagNames, 0)
        let apiOperation = APIOperation(TagEndpoint.post(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let json, _):
                guard let model: APIResults<TagVO> = JSONHelper.decoding(from: json, with: APIResults<TagVO>.decoder), model.isSuccessful else {
                    completion(nil, APIError.clientError)
                    return
                }
                let tagVOs: [TagVO]? =  model.results.compactMap { result in
                    return result.data?.first
                }
                completion(tagVOs, nil)
                
            case .error(let error, _):
                completion(nil, error)
                
            default:
                completion(nil, APIError.clientError)
            }
        }
    }
    
    
    func unassignTag(tagVO: [TagVO], recordId: Int, completion: @escaping ((Error?) -> Void)) {
        let params: DeleteTagParams = (tagVO, recordId)
        let apiOperation = APIOperation(TagEndpoint.unlink(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let json, _):
                guard let model: APIResults<NoDataModel> = JSONHelper.decoding(from: json, with: APIResults<NoDataModel>.decoder), model.isSuccessful else {
                    completion(APIError.clientError)
                    return
                }
                completion(nil)
                
            case .error(let error, _):
                completion(error)
                
            default:
                completion(APIError.clientError)
            }
        }
    }
    
    func deleteTag(tagVO: [TagVO], completion: @escaping ((Error?) -> Void)) {
        let apiOperation = APIOperation(TagEndpoint.delete(params: tagVO))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let json, _):
                guard let model: APIResults<NoDataModel> = JSONHelper.decoding(from: json, with: APIResults<NoDataModel>.decoder), model.isSuccessful else {
                    completion(APIError.clientError)
                    return
                }
                completion(nil)
                
            case .error(let error, _):
                completion(error)
                
            default:
                completion(APIError.clientError)
            }
        }
    }
    
    func updateTag(tagVO: TagVO, newTagName: String, completion: @escaping ((Error?) -> Void)) {
        let archiveId: Int = AuthenticationManager.shared.session?.selectedArchive?.archiveID ?? 0
        let params: TagUpdateParams = (tagVO, newTagName, archiveId)
        let apiOperation = APIOperation(TagEndpoint.updateTag(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let json, _):
                guard let model: APIResults<TagVO> = JSONHelper.decoding(from: json, with: APIResults<TagVO>.decoder), model.isSuccessful else {
                    completion(APIError.parseError)
                    return
                }
                completion(nil)
                
            case .error(let error, _):
                completion(error)
            default:
                completion(APIError.clientError)
            }
        }
    }
}

class TagsRemoteMockDataSource: TagsRemoteDataSourceInterface {
    var deleteTagError: Error?
    var updateTagError: Error?
    
    func getTagsByArchive(archiveId: Int, completion: @escaping (([TagVO]?, Error?) -> Void)) {
        let tag = TagVO(tagVO: TagVOData(status: nil, tagId: nil, type: nil, createdDT: nil, updatedDT: nil))
        completion([tag], nil)
    }
    
    func addTag(tagNames: [String], recordId: Int, completion: @escaping (([TagLinkVO]?, Error?) -> Void)) {
        let tag = TagLinkVO(tagLinkVO: TagLinkVOData(createdDT: nil, updatedDT: nil, refId: nil, refTable: nil, status: nil, tagId: 123, tagLinkId: 321, type: tagNames.first))
        completion([tag], nil)
    }
    
    func addTagToArchiveOnly(tagNames: [String], completion: @escaping (([TagVO]?, Error?) -> Void)) {
        let tag = TagVO(tagVO: TagVOData(status: nil, tagId: 1, type: nil, createdDT: nil, updatedDT: nil))
        completion([tag], nil)
    }
    
    func unassignTag(tagVO: [TagVO], recordId: Int, completion: @escaping ((Error?) -> Void)) {
        completion(nil)
    }
    
    func deleteTag(tagVO: [TagVO], completion: @escaping ((Error?) -> Void)) {
        completion(deleteTagError)
    }
    
    func updateTag(tagVO: TagVO, newTagName: String, completion: @escaping ((Error?) -> Void)) {
        completion(updateTagError)
    }
}
