//
//  EventsPayloadBuilder.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 05.11.2024.

import Foundation

struct EventsPayloadBuilder {
    
    static func build(accountId: Int,
                      eventAction: any EventAction,
                      version: Int = 1,
                      entityId: String? = nil,
                      data: [String: String] = [String:String]()) -> EventsPayload? {
        let defaultEnv = APIEnvironment.defaultEnv
        let distinctId = defaultEnv == .production ? String(accountId) : "\(defaultEnv):\(String(accountId))"
        let payload = EventsPayload(entity: eventAction.entity,
                                    action: eventAction.action,
                                    version: 1,
                                    entityId: entityId,
                                    body: EventsBodyPayload(event: eventAction.event,
                                                            distinctId: distinctId,
                                                            data: data))
        return payload
    }
    
}
