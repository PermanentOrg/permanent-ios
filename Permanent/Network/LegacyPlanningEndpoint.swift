//
//  LegacyPlanningEndpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.05.2023
//

import Foundation

enum LegacyPlanningEndpoint {
    case getLegacyContact
    case getArchiveSteward(archiveId: Int)
    case setArchiveSteward(archiveDetails: LegacyPlanningArchiveDetails)
    case setAccountSteward(name: String, stewardEmail: String)
    case updateAccountSteward(legacyContactId: String, name: String?, stewardEmail: String?)
    case updateArchiveSteward(directiveId: String, stewardDetails: LegacyPlanningArchiveDetails)
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
        case .getArchiveSteward(_), .getLegacyContact:
            return .get
        case .setArchiveSteward(_), .setAccountSteward(_, _):
            return .post
        case .updateAccountSteward(_, _, _), .updateArchiveSteward:
            return .put
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
        case .getLegacyContact:
            return getLegacyPlanning()
        case .setAccountSteward(let name,let stewardEmail):
            return setAccountSteward(name: name, stewardEmail: stewardEmail)
        case .updateAccountSteward(let legacyContactId, let name, let stewardEmail):
            return updateAccountSteward(legacyContactId: legacyContactId, name: name, stewardEmail: stewardEmail)
        case .updateArchiveSteward(_, stewardDetails: let stewardDetails):
            return updateArchiveSteward(archiveDetails: stewardDetails)
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
        let endpointPath = APIEnvironment.defaultEnv.apiServer
        switch self {
        case .getArchiveSteward(let archiveId):
            return "\(endpointPath)api/v2/directive/archive/\(archiveId)"
        case .setArchiveSteward(_):
            return "\(endpointPath)api/v2/directive"
        case .getLegacyContact, .setAccountSteward(_, _):
            return "\(endpointPath)api/v2/legacy-contact"
        case .updateAccountSteward(let legacyContactId, _, _):
            return "\(endpointPath)api/v2/legacy-contact/\(legacyContactId)"
        case .updateArchiveSteward(directiveId: let directiveId, _):
            return "\(endpointPath)api/v2/directive/\(directiveId)"
        }
    }
}

extension LegacyPlanningEndpoint {
    
    func getLegacyPlanning() -> RequestParameters {
        return [Any]()
    }
    
    func getArchiveSteward() -> RequestParameters {
        return [Any]()
    }
    
    func setArchiveSteward(archiveDetails: LegacyPlanningArchiveDetails) -> RequestParameters {
        return [
            "archiveId": "\(String(describing: archiveDetails.archiveId ?? 0))",
            "stewardEmail": archiveDetails.stewardEmail,
            "type": archiveDetails.type,
            "note": archiveDetails.note,
            "trigger": [
                "type": archiveDetails.triggerType
            ]
        ] as [String : Any]
    }
    
    func updateArchiveSteward(archiveDetails: LegacyPlanningArchiveDetails) -> RequestParameters {
        return [
            "stewardEmail": archiveDetails.stewardEmail,
            "type": archiveDetails.type,
            "note": archiveDetails.note,
            "trigger": [
                "type": archiveDetails.triggerType
            ]
        ] as [String : Any]
    }
    
    func setAccountSteward(name: String, stewardEmail: String) -> RequestParameters {
        return [
            "name": name,
            "email": stewardEmail
        ] as [String : Any]
    }
    
    func updateAccountSteward(legacyContactId: String, name: String?, stewardEmail: String?) -> RequestParameters {
        var body: [String: Any] = [:]
        if let name = name {
            body["name"] = name
        }
        if let stewardEmail = stewardEmail {
            body["email"] = stewardEmail
        }
        
        return body
    }
}
