//  
//  LocnVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 12/11/2020.
//

import Foundation

struct LocnVOData: Model {
    let locnVO: LocnVO?
    
    enum CodingKeys: String, CodingKey {
        case locnVO = "LocnVO"
    }
}

struct LocnVO: Model {
    let locnID: Int?
    let displayName: String?
    let geoCodeLookup: String?
    let streetName, streetNumber, locality: String?
    let postalCode, adminOneName, adminOneCode: JSONAny? // TODO
    let adminTwoName, adminTwoCode: JSONAny? // TODO
    let country, countryCode, geometryType: String?
    let anyLatitude, anyLongitude: JSONAny?
    let boundSouth, boundWest: Double?
    let boundNorth, boundEast: Double?
    let geometryAsArray, geoCodeType, geoCodeResponseAsXML: String?
    let timeZoneID: Int?
    let status, type, createdDT, updatedDT: String?
    
    var latitude: Double? {
        if let latitude = anyLatitude?.value as? Double {
            return latitude
        } else if let latitude = anyLatitude?.value as? String {
            return Double(latitude)
        }
        return nil
    }
    
    var longitude: Double? {
        if let longitude = anyLongitude?.value as? Double {
            return longitude
        } else if let longitude = anyLongitude?.value as? String {
            return Double(longitude)
        }
        return nil
    }
    enum CodingKeys: String, CodingKey {
        case locnID = "locnId"
        case displayName, geoCodeLookup, streetNumber, streetName, postalCode, locality, adminOneName, adminOneCode, adminTwoName, adminTwoCode, country, countryCode, geometryType,  boundSouth, boundWest, boundNorth, boundEast, geometryAsArray, geoCodeType
        case geoCodeResponseAsXML = "geoCodeResponseAsXml"
        case timeZoneID = "timeZoneId"
        case status, type, createdDT, updatedDT
        case anyLatitude = "latitude"
        case anyLongitude = "longitude"
    }
}
