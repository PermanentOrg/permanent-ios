//
//  PinAddressLookupTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 19.10.2026.
//

import CoreLocation
import Foundation
import Testing
@testable import Permanent

/// A map pin turned into an address on the phone, with the old server lookup only as the failsafe.
struct PinAddressLookupTests {
    private struct LookupFailed: Error {}

    @Test("A found address maps to the LocnVO fields and saves with every part")
    func addressMapsToLocnVO() throws {
        let address: PinAddressLookup.Address = ("1 Main St", "New York", "NY", "10001", "United States")

        let locn = try #require(PinAddressLookup.locnVO(from: address, latitude: 40.7128, longitude: -74.006))
        let body = locn.toLocationInputPayload()

        #expect(locn.streetName == "1 Main St")
        #expect(locn.locality == "New York")
        #expect(locn.adminOneName == "NY")
        #expect(locn.country == "United States")
        #expect(locn.latitude == 40.7128 && locn.longitude == -74.006)
        #expect(body["sublocation"] as? String == "1 Main St")
        #expect(body["city"] as? String == "New York")
        #expect(body["state"] as? String == "NY")
        #expect(body["postalCode"] as? String == "10001")
        #expect(body["country"] as? String == "United States")
    }

    @Test("A pin with no address keeps its coordinates and makes no server call")
    func openLandKeepsCoordinates() async throws {
        var serverCalls = 0
        var lookup = PinAddressLookup()
        lookup.geocode = { _, completion in completion(.success(("", nil, nil, nil, nil))) }
        lookup.serverLookup = { _, _, completion in
            serverCalls += 1
            completion(nil)
        }

        let answer = await locate(with: lookup)
        let locn = try #require(answer)

        #expect(locn.latitude == 48.8566 && locn.longitude == 2.3522)
        #expect(locn.streetName == nil && locn.locality == nil && locn.country == nil)
        #expect(serverCalls == 0)
    }

    @Test("A failed phone lookup asks the server once, with the pin's coordinates")
    func phoneFailureFallsBackToServer() async throws {
        var serverCalls: [String] = []
        let serverAnswer = try LocnVO.decoder.decode(LocnVO.self, from: Data(#"{ "locality": "Paris", "latitude": 48.8566, "longitude": 2.3522 }"#.utf8))
        var lookup = PinAddressLookup()
        lookup.geocode = { _, completion in completion(.failure(LookupFailed())) }
        lookup.serverLookup = { latitude, longitude, completion in
            serverCalls.append("\(latitude),\(longitude)")
            completion(serverAnswer)
        }

        let locn = await locate(with: lookup)

        #expect(serverCalls == ["48.8566,2.3522"])
        #expect(locn?.locality == "Paris")
    }

    @Test("When both lookups fail the answer is nil")
    func bothFailuresAnswerNil() async {
        var lookup = PinAddressLookup()
        lookup.geocode = { _, completion in completion(.failure(LookupFailed())) }
        lookup.serverLookup = { _, _, completion in completion(nil) }

        let locn = await locate(with: lookup)

        #expect(locn == nil)
    }

    // MARK: - A place picked from the search

    struct Part: Sendable {
        let types: [String]
        let name: String
    }

    /// The `LocnVO` fields a picked place fills.
    struct Picked: Equatable, Sendable {
        var displayName: String?
        var streetNumber: String?
        var streetName: String?
        var locality: String?
        var adminOneName: String?
        var postalCode: String?
        var country: String?
    }

    struct PickedPlace: Sendable, CustomTestStringConvertible {
        let label: String
        let name: String?
        let parts: [Part]
        let expected: Picked

        var testDescription: String { label }
    }

    static let squareParts = [
        Part(types: ["locality", "political"], name: "Brașov"),
        Part(types: ["administrative_area_level_1", "political"], name: "Județul Brașov"),
        Part(types: ["country", "political"], name: "Romania")
    ]

    static let pickedPlaces = [
        PickedPlace(
            label: "A square with no street",
            name: "Piața Sfatului",
            parts: squareParts,
            expected: Picked(displayName: "Piața Sfatului", locality: "Brașov", adminOneName: "Județul Brașov", country: "Romania")
        ),
        PickedPlace(
            label: "A street address",
            name: "Strada Republicii 5",
            parts: [
                Part(types: ["street_number"], name: "5"),
                Part(types: ["route"], name: "Strada Republicii"),
                Part(types: ["locality", "political"], name: "Brașov"),
                Part(types: ["postal_code"], name: "500030"),
                Part(types: ["country", "political"], name: "Romania")
            ],
            expected: Picked(
                displayName: "Strada Republicii 5", streetNumber: "5", streetName: "Strada Republicii", locality: "Brașov",
                postalCode: "500030", country: "Romania"
            )
        ),
        PickedPlace(label: "No name and no address parts", name: nil, parts: [], expected: Picked())
    ]

    @Test("A picked place keeps its own name and address parts", arguments: pickedPlaces)
    func pickedPlaceMapsToLocnVO(_ place: PickedPlace) throws {
        let locn = try #require(picked(place.name, place.parts))

        #expect(read(locn) == place.expected)
        #expect(locn.latitude == 45.6427 && locn.longitude == 25.5887)
    }

    @Test("A picked square saves its name, city, state and country, and shows its name")
    func pickedSquareSavesEveryPart() throws {
        let locn = try #require(picked("Piața Sfatului", Self.squareParts))
        let body = locn.toLocationInputPayload()

        #expect(body["name"] as? String == "Piața Sfatului")
        #expect(body["city"] as? String == "Brașov")
        #expect(body["state"] as? String == "Județul Brașov")
        #expect(body["country"] as? String == "Romania")
        #expect(body["sublocation"] == nil)
        #expect(locn.addressText == "Piața Sfatului, Brașov, Romania")
    }

    @Test("A place picked on the batch screen is kept as it is; only a dropped pin asks the lookup")
    func batchPickSkipsPinLookup() throws {
        var lookups = 0
        let viewModel = AddLocationViewModel(selectedFiles: [FileModel.mockFile()], commonLocation: nil)
        viewModel.pinAddressLookup.geocode = { _, _ in lookups += 1 }
        viewModel.pinAddressLookup.serverLookup = { _, _, _ in lookups += 1 }
        let place = try #require(picked("Piața Sfatului", Self.squareParts))

        viewModel.pickPlace(place)

        #expect(lookups == 0)
        #expect(viewModel.selectedCoordinates?.latitude == 45.6427)
        #expect(viewModel.locnVO?.displayName == "Piața Sfatului")
        #expect(viewModel.searchText == "Piața Sfatului, Brașov, Romania")

        viewModel.selectedCoordinates = CLLocationCoordinate2D(latitude: 45.65, longitude: 25.6)

        #expect(lookups == 1)
    }

    // MARK: - Helpers

    private func picked(_ name: String?, _ parts: [Part]) -> LocnVO? {
        let addressParts = parts.map { PinAddressLookup.AddressPart(types: $0.types, name: $0.name) }
        return PinAddressLookup.locnVO(placeName: name, parts: addressParts, latitude: 45.6427, longitude: 25.5887)
    }

    private func read(_ locn: LocnVO) -> Picked {
        Picked(
            displayName: locn.displayName, streetNumber: locn.streetNumber, streetName: locn.streetName, locality: locn.locality,
            adminOneName: locn.adminOneName, postalCode: locn.postalCode?.value as? String, country: locn.country
        )
    }

    private func locate(with lookup: PinAddressLookup) async -> LocnVO? {
        await withCheckedContinuation { continuation in
            lookup.locate(latitude: 48.8566, longitude: 2.3522) { continuation.resume(returning: $0) }
        }
    }
}
