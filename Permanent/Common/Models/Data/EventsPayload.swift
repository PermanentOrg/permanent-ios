//
//  EventsPayload.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 28.10.2024.

import Foundation

struct EventsBodyPayload: Codable {
    private let analytics: EventsAnalyticPayload
    
    var event: String {
        return analytics.event
    }
    var distinctId: String {
        return analytics.distinctId
    }
    var data: [String: String] {
        return analytics.data
    }
    
    init(event: String, distinctId: String, data: [String: String]) {
        self.analytics = EventsAnalyticPayload(event: event, distinctId: distinctId, data: data)
    }
    
    private struct EventsAnalyticPayload: Codable {
        let event: String
        let distinctId: String
        let data: [String: String]
    }
}

struct EventsPayload: Codable {
    let entity: String
    let action: String
    let version: Int
    let entityId: String?
    let body: EventsBodyPayload
}
