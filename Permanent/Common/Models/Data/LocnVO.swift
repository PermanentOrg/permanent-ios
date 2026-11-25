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
    // The newer fields; the web saves a location with these and leaves locality and the street parts empty.
    let name, sublocation, city: String?
    let geoCodeLookup: String?
    let streetName, streetNumber, locality, adminOneName: String?
    let postalCode, adminOneCode: JSONAny? // TODO
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
        } else if let latitude = anyLatitude?.value as? Int {
            // A whole-number coordinate (e.g. 40) decodes from JSONAny as Int, which the
            // Double cast above rejects — bridge it so the coordinate isn't silently dropped.
            return Double(latitude)
        } else if let latitude = anyLatitude?.value as? String {
            return Double(latitude)
        }
        return nil
    }

    var longitude: Double? {
        if let longitude = anyLongitude?.value as? Double {
            return longitude
        } else if let longitude = anyLongitude?.value as? Int {
            return Double(longitude)
        } else if let longitude = anyLongitude?.value as? String {
            return Double(longitude)
        }
        return nil
    }
    enum CodingKeys: String, CodingKey {
        case locnID = "locnId"
        case displayName, name, sublocation, city, geoCodeLookup, streetNumber, streetName, postalCode, locality, adminOneName, adminOneCode, adminTwoName, adminTwoCode, country, countryCode, geometryType, boundSouth, boundWest, boundNorth, boundEast, geometryAsArray, geoCodeType
        case geoCodeResponseAsXML = "geoCodeResponseAsXml"
        case timeZoneID = "timeZoneId"
        case status, type, createdDT, updatedDT
        case anyLatitude = "latitude"
        case anyLongitude = "longitude"
    }
}

extension LocnVO {
    /// The address the location rows show: place name, street, city, country.
    /// The name is left out when it is the street, and no part shows twice.
    var addressText: String {
        let streetParts = [streetNumber, streetName].compactMap(Self.text)
        let street = streetParts.isEmpty ? Self.text(sublocation) : streetParts.joined(separator: ", ")
        let streetTexts = [street, Self.text(streetName)].compactMap { $0 }
        let place = (Self.text(name) ?? Self.text(displayName)).flatMap { place in
            streetTexts.contains { $0.localizedCaseInsensitiveContains(place) || place.localizedCaseInsensitiveContains($0) } ? nil : place
        }

        var shown: [String] = []
        for part in [place, street, Self.text(city) ?? Self.text(locality), Self.text(country)].compactMap({ $0 })
        where !shown.contains(where: { $0.caseInsensitiveCompare(part) == .orderedSame }) {
            shown.append(part)
        }
        return shown.joined(separator: ", ")
    }

    private static func text(_ value: String?) -> String? {
        guard let value = value, !value.isEmpty else { return nil }
        return value
    }
}
