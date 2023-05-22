//
//  LegacyPlanningEndpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.05.2023
//

import Foundation

enum LegacyPlanningEndpoint {
    case getArchiveSteward(archiveId: Int)
    case setArchiveSteward(archiveDetails: LegacyPlanningArchiveDetails)
}

extension LegacyPlanningEndpoint: RequestProtocol {
    var path: String {
        return ""
    }
    
    var headers: RequestHeaders? {
        return ["content-type": "application/json"]
    }
    
    var method: RequestMethod {
        switch self {
        case .getArchiveSteward(_):
            return .get
        case .setArchiveSteward(_):
            return .post
        }
    }
    
    var requestType: RequestType {
        return .data
    }
    
    var responseType: ResponseType {
        return .json
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .getArchiveSteward(_):
            return getArchiveSteward()
        case .setArchiveSteward(let archiveDetails):
            return setArchiveSteward(archiveDetails: archiveDetails)
        }
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
        let endpointPath = APIEnvironment.defaultEnv.stelaServer
        switch self {
        case .getArchiveSteward(let archiveId):
            return "\(endpointPath)api/v2/directive/archive/\(archiveId)"
        case .setArchiveSteward(_):
            return "\(endpointPath)api/v2/directive"
        }
    }
}

extension LegacyPlanningEndpoint {
    func getArchiveSteward() -> RequestParameters {
        return [Any]()
    }
    
    func setArchiveSteward(archiveDetails: LegacyPlanningArchiveDetails) -> RequestParameters {
        return [
            "archiveId": "\(archiveDetails.archiveId)",
            "stewardEmail": archiveDetails.stewardEmail,
            "type": archiveDetails.type,
            "note": archiveDetails.note,
            "trigger": [
                "type": archiveDetails.triggerType
            ]
        ] as [String : Any]
    }
}
