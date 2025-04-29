//
//  EventsEndpoint.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 28.10.2024.

import Foundation

enum EventsEndpoint {
    case sendEvent(eventsPayload: EventsPayload)
    case checklist
}

extension EventsEndpoint: RequestProtocol {
    var path: String {
        ""
    }
    
    var method: RequestMethod {
        switch self {
        case .checklist:
            return .get
        case .sendEvent:
            return .post
        }
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .sendEvent(let eventsPayload):
            getEventParameters(eventsPayload: eventsPayload)
        case .checklist:
            checklistMember()
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
        switch self {
        case .sendEvent(let eventsPayload):
            return encodePayload(eventsPayload)
        default:
            return nil
        }
    }
    
    var customURL: String? {
        let endpointPath = APIEnvironment.defaultEnv.apiServer
        return "\(endpointPath)api/v2/event"
    }
}

extension EventsEndpoint {
    func getEventParameters(eventsPayload: EventsPayload) -> RequestParameters {
        let parameters: [String : Any] = [
            "entity": eventsPayload.entity,
            "action": eventsPayload.action,
            "version": eventsPayload.version,
            "entityId": eventsPayload.entityId,
            "body": [
                "analytics": [
                    "event": eventsPayload.body.event,
                    "distinctId": eventsPayload.body.distinctId,
                    "data": []
                ]
            ]
        ]
        return parameters
    }
    
    func encodePayload(_ payload: EventsPayload) -> Data? {
        let encoder = JSONEncoder()
        
        do {
            let jsonData = try encoder.encode(payload)
            return jsonData
        } catch {
            print("Encoding error: \(error)")
            return nil
        }
    }
    
    func checklistMember() -> RequestParameters {
        return []
    }
}
