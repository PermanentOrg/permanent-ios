//  
//  TimezoneVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

struct TimezoneVO: Codable {
    let timeZoneID: Int?
    let displayName, timeZonePlace, stdName, stdAbbrev: String?
    let stdOffset, dstName, dstAbbrev, dstOffset: String?
    let countryCode, country, status, type: String?
    let createdDT, updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case timeZoneID = "timeZoneId"
        case displayName, timeZonePlace, stdName, stdAbbrev, stdOffset, dstName, dstAbbrev, dstOffset, countryCode, country, status, type, createdDT, updatedDT
    }
}
