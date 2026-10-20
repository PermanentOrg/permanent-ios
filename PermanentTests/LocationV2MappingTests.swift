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
        var name: String?
        var sublocation: String?
        var city: String?
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
                country: "France", displayName: "Home", latitude: 48.8566, longitude: 2.3522,
                name: "Home", sublocation: "12 Rue Cler", city: "Paris"
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

    // MARK: - Address text

    struct TextCase: Sendable, CustomTestStringConvertible {
        let label: String
        let locnVO: String
        let text: String

        var testDescription: String { label }
    }

    static let textCases = [
        TextCase(
            label: "Saved on the web: name and city, no locality",
            locnVO: """
            { "locnId": 9, "name": "Piața Sfatului", "city": "Brașov", "adminOneName": "Județul Brașov", "country": "Romania",
            "locality": null, "latitude": 45.6427, "longitude": 25.5887 }
            """,
            text: "Piața Sfatului, Brașov, Romania"
        ),
        TextCase(
            label: "Saved through V1: street parts and locality",
            locnVO: """
            { "locnId": 1952, "displayName": null, "streetNumber": "1398", "streetName": "Great Highway",
            "locality": "San Francisco", "adminOneName": "California", "country": "United States" }
            """,
            text: "1398, Great Highway, San Francisco, United States"
        ),
        TextCase(
            label: "Sublocation and city only",
            locnVO: #"{ "sublocation": "12 Rue Cler", "city": "Paris", "country": "France" }"#,
            text: "12 Rue Cler, Paris, France"
        ),
        TextCase(
            label: "A name equal to the city",
            locnVO: #"{ "name": "Brașov", "city": "Brașov", "country": "Romania" }"#,
            text: "Brașov, Romania"
        ),
        TextCase(
            label: "A name that is the street",
            locnVO: """
            { "name": "Strada Republicii 5", "streetNumber": "5", "streetName": "Strada Republicii", "locality": "Brașov",
            "country": "Romania" }
            """,
            text: "5, Strada Republicii, Brașov, Romania"
        ),
        TextCase(
            label: "Coordinates only",
            locnVO: #"{ "latitude": 45.6427, "longitude": 25.5887 }"#,
            text: ""
        )
    ]

    @Test("A location shows one address text: name, street, city, country", arguments: textCases)
    func addressText(_ testCase: TextCase) throws {
        let locn = try LocnVO.decoder.decode(LocnVO.self, from: Data(testCase.locnVO.utf8))

        #expect(locn.addressText == testCase.text)
    }

    @Test("A location saved on the web shows the same text through V2 and V1, and saves its name and city")
    func webLocationReadsTheSameOnBothPaths() throws {
        let throughV2 = try #require(try locnVO(from: """
            { "id": "9", "name": "Piața Sfatului", "city": "Brașov", "state": "Județul Brașov", "country": "Romania",
            "latitude": 45.6427, "longitude": 25.5887, "locality": null, "streetName": null }
            """, on: .record))
        let throughV1 = try LocnVO.decoder.decode(LocnVO.self, from: Data(Self.textCases[0].locnVO.utf8))
        let body = throughV1.toLocationInputPayload()

        #expect(throughV2.addressText == "Piața Sfatului, Brașov, Romania")
        #expect(throughV1.addressText == throughV2.addressText)
        #expect(body["name"] as? String == "Piața Sfatului")
        #expect(body["city"] as? String == "Brașov")
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
            displayName: locn.displayName, latitude: locn.latitude, longitude: locn.longitude,
            name: locn.name, sublocation: locn.sublocation, city: locn.city
        )
    }
}
