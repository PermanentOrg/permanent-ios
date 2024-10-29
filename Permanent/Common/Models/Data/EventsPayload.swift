//
//  EventsPayload.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 28.10.2024.

import Foundation

struct EventsBodyPayload: Codable {
    let event: String
    let distinctId: String
    let data: [String: String]
}

struct EventsPayload: Codable {
    let entity: String
    let action: String
    let version: Int
    let entityId: String?
    let body: EventsBodyPayload
}
