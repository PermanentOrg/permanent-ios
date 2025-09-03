//
//  ShareLinksV2Endpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.08.2025.
//

import Foundation

enum ShareLinksV2Endpoint {
    case createShareLink(
        file: FileModel, 
        permissionsLevel: String = "viewer",
        accessRestrictions: String = "none",
        maxUses: Int? = nil, 
        expirationTimestamp: String? = nil
    )
}

extension ShareLinksV2Endpoint: RequestProtocol {
    var parameters: RequestParameters? {
        switch self {
        case .createShareLink(let file, let permissionsLevel, let accessRestrictions, let maxUses, let expirationTimestamp):
            return createShareLink(
                file: file, 
                permissionsLevel: permissionsLevel,
                accessRestrictions: accessRestrictions,
                maxUses: maxUses, 
                expirationTimestamp: expirationTimestamp
            )
        }
    }
    
    var path: String {
        return ""
    }
    
    var method: RequestMethod {
        switch self {
        case .createShareLink:
            return .post
        }
    }
    
    var headers: RequestHeaders? {
        switch self {
        case .createShareLink:
            return ["content-type": "application/json; charset=utf-8"]
        }
    }
    
    var requestType: RequestType {
        return .data
    }
    
    var responseType: ResponseType {
        return .json
    }
    
    var progressHandler: ProgressHandler? {
        get {
            nil
        }
        set {}
    }
    
    var bodyData: Data? {
        return nil
    }
    
    var customURL: String? {
        let endpointPath = APIEnvironment.defaultEnv.apiServer
        switch self {
        case .createShareLink:
            return "\(endpointPath)api/v2/share-links"
        }
    }
}

extension ShareLinksV2Endpoint {
    func createShareLink(
        file: FileModel, 
        permissionsLevel: String = "viewer",
        accessRestrictions: String = "none",
        maxUses: Int? = nil, 
        expirationTimestamp: String? = nil
    ) -> RequestParameters {
        var itemId: Int
        if file.type.isFolder {
            itemId = file.folderId
        } else {
            itemId = file.recordId
        }
        
        let itemType: String
        if file.type.isFolder {
            itemType = "folder"
        } else {
            itemType = "record"
        }
        
        var parameters: [String: Any] = [
            "itemId": "\(itemId)",
            "itemType": itemType,
            "permissionsLevel": permissionsLevel,
            "accessRestrictions": accessRestrictions
        ]
        
        // Add optional parameters only if they are provided
        if let maxUses = maxUses {
            parameters["maxUses"] = maxUses
        }
        
        if let expirationTimestamp = expirationTimestamp {
            parameters["expirationTimestamp"] = expirationTimestamp
        }
        
        return parameters
    }
}

