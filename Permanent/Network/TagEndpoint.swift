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

enum TagEndpoint {
    case getByArchive(params: GetTagsByArchiveParams)
    case post(params: TagParams)
    case delete(params: [TagVO])
    case unlink(params: DeleteTagParams)
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
            return Payloads.tagPost(params: params)
            
        case .delete(let params):
            return Payloads.deleteTagPost(tags: params)
            
        case .getByArchive(let params):
            return Payloads.getTagsByArchive(params: params)
            
        case .unlink(let params):
            return Payloads.deleteTagLinkPost(params: params)
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
