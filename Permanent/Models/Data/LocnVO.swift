//  
//  LocnVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 12/11/2020.
//

import Foundation

struct LocnVO: Model {
    let locnID: Int?
    let displayName: String?
    let geoCodeLookup: String?
    let streetNumber: JSONAny? // TODO
    let streetName: String?
    let postalCode, locality, adminOneName, adminOneCode: JSONAny? // TODO
    let adminTwoName, adminTwoCode: JSONAny? // TODO
    let country, countryCode, geometryType: String?
    let latitude, longitude, boundSouth, boundWest: Double?
    let boundNorth, boundEast: Double?
    let geometryAsArray, geoCodeType, geoCodeResponseAsXML: String?
    let timeZoneID: Int?
    let status, type, createdDT, updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case locnID = "locnId"
        case displayName, geoCodeLookup, streetNumber, streetName, postalCode, locality, adminOneName, adminOneCode, adminTwoName, adminTwoCode, country, countryCode, geometryType, latitude, longitude, boundSouth, boundWest, boundNorth, boundEast, geometryAsArray, geoCodeType
        case geoCodeResponseAsXML = "geoCodeResponseAsXml"
        case timeZoneID = "timeZoneId"
        case status, type, createdDT, updatedDT
    }
}
