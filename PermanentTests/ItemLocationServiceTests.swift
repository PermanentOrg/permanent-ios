//
//  ItemLocationServiceTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 19.10.2026.
//

import Foundation
import Testing
@testable import Permanent

/// The one Stela V2 location writer and folder reader that both item screens call.
struct ItemLocationServiceTests {
    private let expectedBody: [String: Any] = [
        "sublocation": "1 Main St", "city": "New York", "state": "NY", "postalCode": "10001",
        "country": "United States", "latitude": 40.7128, "longitude": -74.006
    ]

    // MARK: - Saving

    @Test("A record save sends the location body to the record PATCH")
    func recordSaveUsesRecordPatch() async throws {
        let server = FakeServer()
        let outcome = await save(try location(), to: [try item(#""recordId": "301""#)], server: server)

        #expect(outcome)
        #expect(server.calls.map(\.route) == ["record 301"])
        let body = try #require(server.calls.first?.fields["location"] as? [String: Any])
        #expect(NSDictionary(dictionary: body) == NSDictionary(dictionary: expectedBody))
        #expect(server.calls.first?.fields.count == 1, "the server rejects any other key")
    }

    @Test("A folder save sends the same body to the folder PATCH")
    func folderSaveUsesFolderPatch() async throws {
        let server = FakeServer()
        let outcome = await save(try location(), to: [try item(#""folderId": "55", "type": "type.folder.private""#)], server: server)

        #expect(outcome)
        #expect(server.calls.map(\.route) == ["folder 55"])
        let body = try #require(server.calls.first?.fields["location"] as? [String: Any])
        #expect(NSDictionary(dictionary: body) == NSDictionary(dictionary: expectedBody))
    }

    @Test("A mixed list is saved one item at a time, in order")
    func mixedListSavesInOrder() async throws {
        let server = FakeServer()
        let files = try [item(#""recordId": "301""#), item(#""folderId": "55", "type": "type.folder.private""#), item(#""recordId": "302""#)]

        let outcome = await save(try location(), to: files, server: server)

        #expect(outcome)
        #expect(server.calls.map(\.route) == ["record 301", "folder 55", "record 302"])
    }

    @Test("The first failed PATCH stops the save and answers false")
    func firstFailureStops() async throws {
        let server = FakeServer(failingRoute: "folder 55")
        let files = try [item(#""recordId": "301""#), item(#""folderId": "55", "type": "type.folder.private""#), item(#""recordId": "302""#)]

        let outcome = await save(try location(), to: files, server: server)

        #expect(!outcome)
        #expect(server.calls.map(\.route) == ["record 301", "folder 55"])
    }

    @Test("A location with no field, or an item with no Stela id, sends nothing and answers false")
    func nothingToSendAnswersFalse() async throws {
        let server = FakeServer()
        let empty = await save(try location(#"{ "streetName": "" }"#), to: [try item(#""recordId": "301""#)], server: server)
        let unsaved = await save(try location(), to: [try item(#""recordId": "301""#), try item(#""recordId": "-1""#)], server: server)

        #expect(!empty)
        #expect(!unsaved)
        #expect(server.calls.isEmpty)
    }

    // MARK: - Reading a folder

    @Test("A folder's location is read from Stela V2, and an empty one is nil", arguments: [
        (#"{ "items": [ { "folderId": "55", "location": { "id": "3", "city": "Paris", "country": "France" } } ] }"#, "Paris"),
        (#"{ "items": [ { "folderId": "55", "location": { "id": null, "city": null, "latitude": null } } ] }"#, nil),
        ("", nil)
    ] as [(String, String?)])
    func folderLocationReadsStela(response: String, expectedCity: String?) async throws {
        var askedFor: [String] = []
        var service = ItemLocationService()
        service.fetchFolder = { folderId, completion in
            askedFor.append(folderId)
            let json = try? JSONSerialization.jsonObject(with: Data(response.utf8))
            completion(json == nil ? .error(nil, nil) : .json(json, nil))
        }

        let location = await withCheckedContinuation { continuation in
            service.folderLocation(folderId: 55) { continuation.resume(returning: $0) }
        }

        #expect(askedFor == ["55"])
        #expect(location?.locality == expectedCity)
        #expect((location == nil) == (expectedCity == nil))
    }

    // MARK: - Helpers

    /// Records each PATCH and answers it at once.
    private final class FakeServer {
        let failingRoute: String?
        var calls: [(route: String, fields: [String: Any])] = []

        init(failingRoute: String? = nil) {
            self.failingRoute = failingRoute
        }

        func patch(_ route: String, _ fields: [String: Any], _ completion: (Bool) -> Void) {
            calls.append((route, fields))
            completion(route != failingRoute)
        }
    }

    private func save(_ location: LocnVO, to files: [FileModel], server: FakeServer) async -> Bool {
        var service = ItemLocationService()
        service.patchRecord = { file, fields, completion in server.patch("record \(file.recordId)", fields, completion) }
        service.patchFolder = { file, fields, completion in server.patch("folder \(file.folderId)", fields, completion) }
        return await withCheckedContinuation { continuation in
            service.save(location, to: files) { continuation.resume(returning: $0) }
        }
    }

    private func location(_ json: String? = nil) throws -> LocnVO {
        let fields = json ?? """
        { "streetName": "1 Main St", "locality": "New York", "adminOneName": "NY", "postalCode": "10001",
        "country": "United States", "latitude": 40.7128, "longitude": -74.006 }
        """
        return try LocnVO.decoder.decode(LocnVO.self, from: Data(fields.utf8))
    }

    private func item(_ fields: String) throws -> FileModel {
        let json = #"{ "items": [ { "type": "type.record.image", "folderLinkId": "900", \#(fields) } ] }"#
        let response = try FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: Data(json.utf8))
        let item = try #require(response.items?.first)
        return FileModel(model: item, permissions: [.read, .edit], accessRole: .editor)
    }
}
