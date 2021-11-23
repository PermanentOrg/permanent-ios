//
//  SearchEndpoint.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 03.11.2021.
//

import Foundation

enum SearchEndpoint {
    case folderAndRecord(text: String, tagVOs: [TagVOData])
}

extension SearchEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .folderAndRecord:
            return "/search/folderAndRecord"
        }
    }
    
    var method: RequestMethod {
        return .post
    }
    
    var headers: RequestHeaders? {
        return [
            "content-type": "application/json"
        ]
    }
    
    var requestType: RequestType {
        return .data
    }
    
    var responseType: ResponseType {
        return .json
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .folderAndRecord(let text, let tags):
            return Payloads.searchFolderAndRecord(text: text, tags: tags)
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
