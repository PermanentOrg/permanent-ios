//
//  TagEndpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.03.2021.
//

import Foundation

typealias TagParams = (name: String, refID: Int, csrf: String)
typealias DeleteTagParams = (tagVO: TagVO, refID: Int, csrf: String)
typealias GetTagsByArchiveParams = (archiveId: Int, csrf: String)

enum TagEndpoint {
    case tagPost(params: TagParams)
    case tagDelete(params: DeleteTagParams)
    case getTagsByArchive(params: GetTagsByArchiveParams)
}

extension TagEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .tagPost:
            return "/tag/post"
        case .tagDelete:
            return "/tag/delete"
        case .getTagsByArchive:
            return "/tag/getTagsByArchive"
        }
    }
    
    var method: RequestMethod {
        switch self {
        case .tagPost,.tagDelete,.getTagsByArchive:
            return .post
        }
    }
    
    var headers: RequestHeaders? {
        switch self {
        case .tagPost,.tagDelete,.getTagsByArchive:
            return [
                "content-type": "application/json"
            ]
        }
    }
    
    var requestType: RequestType {
        switch self {
        case .tagPost,.tagDelete,.getTagsByArchive:
            return .data
        }
    }
    
    var responseType: ResponseType {
        switch self {
        case .tagPost,.tagDelete,.getTagsByArchive:
            return .json
        }
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .tagPost(let params):
            return Payloads.tagPost(params: params)
        case .tagDelete(let params):
            return Payloads.deletePost(params: params)
        case .getTagsByArchive(let params):
            return Payloads.getTagsByArchive(params: params)
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
