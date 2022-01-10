//
//  APIPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09/11/2020.
//

import Foundation

struct APIPayload<T: Model>: Model {
    let requestVO: RequestVOData<T>
    
    enum CodingKeys: String, CodingKey {
        case requestVO = "RequestVO"
    }
    
    static func make(fromData data: [T]) -> APIPayload<T> {
        let voData = RequestVOData(
            data: data,
            csrf: PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.csrfStorageKey)
        )
        return APIPayload(requestVO: voData)
    }
}

struct RequestVOData<T: Model>: Model {
    let data: [T]
    let csrf: String?
}
