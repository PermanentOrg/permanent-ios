//
//  TagEndpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.03.2021.
//

import Foundation

typealias TagParams = (names: [String], refID: Int)
typealias DeleteTagParams = (tagVO: [TagVO], refID: Int)
typealias GetTagsByArchiveParams = (Int)
typealias TagUpdateParams = (tag: TagVO, newTagName: String, archiveId: Int)

enum TagEndpoint {
    case getByArchive(params: GetTagsByArchiveParams)
    case post(params: TagParams)
    case delete(params: [TagVO])
    case unlink(params: DeleteTagParams)
    case updateTag(params: TagUpdateParams)
}

extension TagEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .post:
            return "/tag/post"
        case .delete:
            return "/tag/delete"
        case .getByArchive:
            return "/tag/getTagsByArchive"
        case .unlink:
            return "/tag/DeleteTagLink"
        case .updateTag:
            return "/tag/updateTag"
        }
    }
    
    var method: RequestMethod {
        return .post
    }
    
    var requestType: RequestType {
        return .data
    }
    
    var responseType: ResponseType {
        return .json
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .post(let params):
            return tagPost(params: params)
            
        case .delete(let params):
            return  deleteTagPost(tags: params)
            
        case .getByArchive(let params):
            return  getTagsByArchive(params: params)
            
        case .unlink(let params):
            return  deleteTagLinkPost(params: params)
            
        case .updateTag(let params):
            return  updateTagPost(params: params)
        }
    }
    
    var progressHandler: ProgressHandler? {
        get {
            nil
        }
        set {}
    }
    
    var bodyData: Data? {
        nil
    }
    
    var customURL: String? {
        nil
    }
}

extension TagEndpoint {
    func tagPost(params: TagParams) -> RequestParameters {
        let tagLinkVO: [String: Any] = [
            "refId": params.refID,
            "refTable": "record"
        ]
        
        let data = params.names.map {
            [
                "TagLinkVO": tagLinkVO,
                "TagVO": [
                    "name": $0
                ]
            ]
        }
        
        return [
            "RequestVO":
                [
                    "data": data
                ]
        ]
    }
    
    func deleteTagPost(tags: [TagVO]) -> RequestParameters {
        let data = tags.map {
            [
                "TagVO": [
                    "id": ($0.tagVO.tagId ?? Int() ) as Int
                ]
            ]
        }
        
        return [
            "RequestVO":
                [
                    "data": data
                ]
        ]
    }
    
    func getTagsByArchive(params: GetTagsByArchiveParams) -> RequestParameters {
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "ArchiveVO": [
                                "archiveId": params
                            ]
                        ]
                    ]
                ]
        ]
    }
    
    func deleteTagLinkPost(params: DeleteTagParams) -> RequestParameters {
        let tagLinkVO: [String: Any] = [
            "refId": params.refID,
            "refTable": "record"
        ]
        
        let data = params.tagVO.map {
            [
                "TagLinkVO": tagLinkVO,
                "TagVO": [
                    "name": ($0.tagVO.name ?? String() ) as String,
                    "tagId": ($0.tagVO.tagId ?? Int() ) as Int
                ]
            ]
        }
        
        return [
            "RequestVO":
                [
                    "data": data
                ]
        ]
    }
    
    func updateTagPost(params: TagUpdateParams) -> RequestParameters {
        guard let tagId = params.tag.tagVO.tagId else { return [] }
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "TagVO": [
                                "name": params.newTagName,
                                "archiveId": params.archiveId,
                                "tagId": tagId
                            ]
                        ]
                    ]
                ]
        ]
    }
}
