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

    // MARK: - Helpers

    private func locate(with lookup: PinAddressLookup) async -> LocnVO? {
        await withCheckedContinuation { continuation in
            lookup.locate(latitude: 48.8566, longitude: 2.3522) { continuation.resume(returning: $0) }
        }
    }
}
