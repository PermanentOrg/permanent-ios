//
//  APIPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09/11/2020.
//

import Foundation

struct APIPayload<T: Model>: Model {
    let RequestVO: RequestVOData<T>
    
    // TODO: Make csrf global
    static func make(fromData data: [T], csrf: String) -> APIPayload<T> {
        let voData = RequestVOData(
            data: data,
            apiKey: Constants.API.apiKey,
            csrf: csrf
        )
        return APIPayload(RequestVO: voData)
    }
}

struct RequestVOData<T: Model>: Model {
    let data: [T]
    let apiKey: String
    let csrf: String?
}
