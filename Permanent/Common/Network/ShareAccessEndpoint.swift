//
//  ShareAccessEndpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.03.2026.
//

import Foundation

enum ShareAccessEndpoint {
    case inviteShare(
        email: String,
        byArchiveId: Int,
        fullName: String,
        accessRole: String,
        folderLinkId: Int,
        relationship: String,
        folderId: Int
    )
}

extension ShareAccessEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .inviteShare:
            return "/invite/share"
        }
    }

    var method: RequestMethod { .post }

    var requestType: RequestType { .data }

    var responseType: ResponseType { .json }

    var parameters: RequestParameters? {
        switch self {
        case .inviteShare(
            email: let email,
            byArchiveId: let byArchiveId,
            fullName: let fullName,
            accessRole: let accessRole,
            folderLinkId: let folderLinkId,
            relationship: let relationship,
            folderId: let folderId
        ):
            return [
                "email": email,
                "byArchiveId": byArchiveId,
                "fullName": fullName,
                "accessRole": accessRole,
                "folderLinkId": folderLinkId,
                "relationship": relationship,
                "folderId": folderId
            ]
        }
    }

    var headers: RequestHeaders? {
        [
            "content-type": "application/json; charset=utf-8",
            "Request-Version": "2"
        ]
    }

    var progressHandler: ProgressHandler? {
        get { nil }
        set { }
    }

    var bodyData: Data? { nil }

    var customURL: String? { nil }
}
