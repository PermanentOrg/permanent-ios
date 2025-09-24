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
    case updateShareLink(
        shareLinkId: String,
        permissionsLevel: String? = nil,
        accessRestrictions: String? = nil,
        maxUses: Int? = nil,
        expirationTimestamp: String? = nil
    )
    case getShareLink(shareLinkId: String)
    case deleteShareLink(shareLinkId: String)
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
        case .updateShareLink(_, let permissionsLevel, let accessRestrictions, let maxUses, let expirationTimestamp):
            return updateShareLinkParameters(
                permissionsLevel: permissionsLevel,
                accessRestrictions: accessRestrictions,
                maxUses: maxUses,
                expirationTimestamp: expirationTimestamp
            )
        case .getShareLink:
            return nil
        case .deleteShareLink:
            return nil
        }
    }
    
    var path: String {
        return ""
    }
    
    var method: RequestMethod {
        switch self {
        case .createShareLink:
            return .post
        case .updateShareLink:
            return .patch
        case .getShareLink:
            return .get
        case .deleteShareLink:
            return .delete
        }
    }
    
    var headers: RequestHeaders? {
        switch self {
        case .createShareLink:
            return ["content-type": "application/json; charset=utf-8"]
        case .updateShareLink:
            return ["content-type": "application/json; charset=utf-8"]
        case .getShareLink:
            return nil
        case .deleteShareLink:
            return nil
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
        case .updateShareLink(let shareLinkId, _, _, _, _):
            return "\(endpointPath)api/v2/share-links/\(shareLinkId)"
        case .getShareLink(let shareLinkId):
            return "\(endpointPath)api/v2/share-links?shareLinkIds[]=\(shareLinkId)"
        case .deleteShareLink(let shareLinkId):
            return "\(endpointPath)api/v2/share-links/\(shareLinkId)"
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
    
    func updateShareLinkParameters(
        permissionsLevel: String? = nil,
        accessRestrictions: String? = nil,
        maxUses: Int? = nil,
        expirationTimestamp: String? = nil
    ) -> RequestParameters {
        var parameters: [String: Any] = [:]
        
        // Add optional parameters only if they are provided
        if let permissionsLevel = permissionsLevel {
            parameters["permissionsLevel"] = permissionsLevel
        }
        
        if let accessRestrictions = accessRestrictions {
            parameters["accessRestrictions"] = accessRestrictions
        }
        
        if let maxUses = maxUses {
            parameters["maxUses"] = maxUses
        }
        
        if let expirationTimestamp = expirationTimestamp {
            if expirationTimestamp == "null" {
                // Explicitly set to NSNull to send JSON null
                parameters["expirationTimestamp"] = NSNull()
            } else {
                parameters["expirationTimestamp"] = expirationTimestamp
            }
        }
        
        return parameters
    }
}

