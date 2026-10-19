//
//  LocationV2MappingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 19.10.2026.
//

import Foundation
import Testing
@testable import Permanent

/// A Stela V2 location, on a record or on a folder, mapped to the `LocnVO` the screens read.
struct LocationV2MappingTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let label: String
        let location: String
        let expected: Read?

        var testDescription: String { label }
    }

    /// The `LocnVO` fields the Location rows and the map read.
    struct Read: Equatable, Sendable {
        var streetNumber: String?
        var streetName: String?
        var locality: String?
        var adminOneName: String?
        var postalCode: String?
        var country: String?
        var countryCode: String?
        var displayName: String?
        var latitude: Double?
        var longitude: Double?
    }

    enum Source: String, CaseIterable, Sendable, CustomTestStringConvertible {
        case record, folder

        var testDescription: String { rawValue }
    }

    static let cases = [
        Case(
            label: "New fields only, as the web saves them",
            location: """
            { "id": "7", "name": "Home", "sublocation": "12 Rue Cler", "city": "Paris", "state": "Ile-de-France",
            "postalCode": "75007", "country": "France", "latitude": 48.8566, "longitude": 2.3522,
            "streetNumber": null, "streetName": null, "locality": null, "countryCode": null, "displayName": null }
            """,
            expected: Read(
                streetName: "12 Rue Cler", locality: "Paris", adminOneName: "Ile-de-France", postalCode: "75007",
                country: "France", displayName: "Home", latitude: 48.8566, longitude: 2.3522
            )
        ),
        Case(
            label: "Old fields only, as V1 saved them",
            location: """
            { "id": "8", "streetNumber": "1", "streetName": "Main St", "locality": "New York", "state": "NY",
            "country": "United States", "countryCode": "US", "displayName": "Office", "latitude": 40.7128, "longitude": -74.006 }
            """,
            expected: Read(
                streetNumber: "1", streetName: "Main St", locality: "New York", adminOneName: "NY",
                country: "United States", countryCode: "US", displayName: "Office", latitude: 40.7128, longitude: -74.006
            )
        ),
        Case(
            label: "An all-null object, as Stela sends for an item with no location",
            location: """
            { "id": null, "name": null, "sublocation": null, "city": null, "state": null, "postalCode": null, "country": null,
            "latitude": null, "longitude": null, "streetNumber": null, "streetName": null, "locality": null, "county": null,
            "countryCode": null, "displayName": null, "timezone": null }
            """,
            expected: nil
        ),
        Case(
            label: "Only a time zone and an empty city",
            location: #"{ "id": "7", "timezone": "Europe/Paris", "city": "" }"#,
            expected: nil
        ),
        Case(
            label: "Whole-number coordinates",
            location: #"{ "id": "9", "latitude": 40, "longitude": -74 }"#,
            expected: Read(latitude: 40, longitude: -74)
        )
    ]

    @Test("A Stela location maps to the LocnVO the screens read", arguments: cases, Source.allCases)
    func mapsToLocnVO(_ testCase: Case, source: Source) throws {
        let locn = try locnVO(from: testCase.location, on: source)

        #expect(locn.map(read) == testCase.expected)
    }

    // MARK: - Helpers

    private func locnVO(from location: String, on source: Source) throws -> LocnVO? {
        switch source {
        case .record:
            let json = #"{ "data": { "recordId": "8", "type": "type.record.image", "location": \#(location) } }"#
            let data = try #require(try RecordV2Response.decoder.decode(RecordV2Response.self, from: Data(json.utf8)).data)
            let recordVO = try #require(JSONHelper.decoding(from: data.toRecordVOPayload(), with: RecordVO.decoder) as RecordVO?)
            return recordVO.recordVO?.locnVO

        case .folder:
            let json = #"{ "items": [ { "folderId": "55", "type": "type.folder.private", "location": \#(location) } ] }"#
            let folder = try #require(try FolderV2Response.decoder.decode(FolderV2Response.self, from: Data(json.utf8)).items?.first)
            guard let payload = folder.location?.toLocnVOPayload() else { return nil }
            return try #require(JSONHelper.decoding(from: payload, with: LocnVO.decoder) as LocnVO?)
        }
    }

    private func read(_ locn: LocnVO) -> Read {
        Read(
            streetNumber: locn.streetNumber, streetName: locn.streetName, locality: locn.locality, adminOneName: locn.adminOneName,
            postalCode: locn.postalCode?.value as? String, country: locn.country, countryCode: locn.countryCode,
            displayName: locn.displayName, latitude: locn.latitude, longitude: locn.longitude
        )
    }
}
