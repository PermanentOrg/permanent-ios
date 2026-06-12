//
//  RelationEndpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.05.2026.
//

import Foundation

enum RelationEndpoint {
    case getAll(archiveId: Int)
}

extension RelationEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .getAll:
            return "/relation/getAll"
        }
    }

    var method: RequestMethod { .post }

    var requestType: RequestType { .data }

    var responseType: ResponseType { .json }

    var parameters: RequestParameters? {
        switch self {
        case .getAll(let archiveId):
            return getAllRelationsPayload(archiveId: archiveId)
        }
    }

    var progressHandler: ProgressHandler? {
        get { nil }
        set {}
    }

    var bodyData: Data? { nil }

    var customURL: String? { nil }
}

extension RelationEndpoint {
    func getAllRelationsPayload(archiveId: Int) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [
                        "RelationVO": [
                            "archiveId": archiveId
                        ]
                    ]
                ]
            ]
        ]
    }
}
