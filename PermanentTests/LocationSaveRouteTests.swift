//
//  LocationSaveRouteTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 19.10.2026.
//

import Foundation
import Testing
@testable import Permanent

/// Which server calls a location save makes: Stela V2 first, and the old V1 call only after a V2 failure.
@MainActor
struct LocationSaveRouteTests {
    // MARK: - Details save

    @Test("A details location save sends one V2 PATCH and no V1 call, in any archive the member may edit", arguments: ["5", "9"])
    func detailsSaveGoesToV2(archiveId: String) async throws {
        let file = try record(#""recordId": "301", "archiveId": "\#(archiveId)""#)
        let server = FakeServer(patchSucceeds: true)
        let viewModel = previewViewModel(file: file, server: server)
        let location = try picked()

        let outcome = await result { done in
            viewModel.update(file: file, name: nil, description: nil, date: nil, location: location, completion: done)
        }

        #expect(outcome == true)
        #expect(server.patches.map(\.recordId) == [301])
        let body = try #require(server.patches.first?.fields["location"] as? [String: Any])
        #expect(body["city"] as? String == "New York")
        #expect(body["latitude"] as? Double == 40.7128)
        #expect(server.patches.first?.fields.count == 1)
        #expect(server.v1Locations.isEmpty)
    }

    @Test("A failed details V2 save sends one V1 update that carries the location")
    func detailsFailureRetriesV1() async throws {
        let file = try record(#""recordId": "301", "archiveId": "5""#)
        let server = FakeServer(patchSucceeds: false)
        let viewModel = previewViewModel(file: file, server: server)
        let location = try picked()

        let outcome = await result { done in
            viewModel.update(file: file, name: nil, description: nil, date: nil, location: location, completion: done)
        }

        #expect(outcome == true)
        #expect(server.patches.count == 1)
        #expect(server.v1Locations.map(\.recordIds) == [[301]])
        #expect(server.v1Locations.first?.location?.locality == "New York")
    }

    // MARK: - Batch save

    @Test("A batch location save sends one V2 PATCH per record and no V1 batch")
    func batchSaveGoesToV2() async throws {
        let server = FakeServer(patchSucceeds: true)
        let viewModel = try batchViewModel(server: server)

        let outcome = await result { done in viewModel.update(completion: done) }

        #expect(outcome == true)
        #expect(!viewModel.isLoading)
        #expect(server.patches.map(\.recordId) == [301, 302])
        #expect(server.patches.allSatisfy { ($0.fields["location"] as? [String: Any])?["city"] as? String == "New York" })
        #expect(server.v1Locations.isEmpty)
    }

    @Test("A failed batch V2 save sends the V1 batch with the location")
    func batchFailureRetriesV1() async throws {
        let server = FakeServer(patchSucceeds: false)
        let viewModel = try batchViewModel(server: server)

        let outcome = await result { done in viewModel.update(completion: done) }

        #expect(outcome == true)
        #expect(server.patches.map(\.recordId) == [301])
        #expect(server.v1Locations.map(\.recordIds) == [[301, 302]])
        #expect(server.v1Locations.first?.location?.locality == "New York")
    }

    // MARK: - Helpers

    /// Records each call the screens make and answers it at once.
    private final class FakeServer {
        let patchSucceeds: Bool
        var patches: [(recordId: Int, fields: [String: Any])] = []
        var v1Locations: [(recordIds: [Int], location: LocnVO?)] = []

        init(patchSucceeds: Bool) {
            self.patchSucceeds = patchSucceeds
        }
    }

    /// The details view model with the record re-read after a save answered locally, not by the server.
    private final class OfflinePreviewViewModel: FilePreviewViewModel {
        override func getRecord(file: FileModel, then handler: @escaping (RecordVO?) -> Void) {
            handler(nil)
        }
    }

    private func picked() throws -> LocnVO {
        let json = #"{ "streetName": "1 Main St", "locality": "New York", "country": "United States", "latitude": 40.7128, "longitude": -74.006 }"#
        return try LocnVO.decoder.decode(LocnVO.self, from: Data(json.utf8))
    }

    private func record(_ fields: String) throws -> FileModel {
        let json = #"{ "items": [ { "type": "type.record.image", "folderLinkId": "900", \#(fields) } ] }"#
        let response = try FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: Data(json.utf8))
        let item = try #require(response.items?.first)
        return FileModel(model: item, permissions: [.read, .edit], accessRole: .editor)
    }

    private func previewViewModel(file: FileModel, server: FakeServer) -> FilePreviewViewModel {
        let viewModel = OfflinePreviewViewModel(file: file)
        viewModel.sessionArchiveId = { 5 }
        viewModel.patchRecordRequest = { recordId, fields, completion in
            server.patches.append((recordId, fields))
            completion(server.patchSucceeds)
        }
        viewModel.updateV1Request = { params, completion in
            server.v1Locations.append(([params.recordId], params.location))
            completion(true)
        }
        return viewModel
    }

    private func batchViewModel(server: FakeServer) throws -> AddLocationViewModel {
        let files = try [record(#""recordId": "301", "archiveId": "5""#), record(#""recordId": "302", "archiveId": "5""#)]
        let viewModel = AddLocationViewModel(selectedFiles: files, commonLocation: nil)
        viewModel.locnVO = try picked()
        viewModel.patchRecordRequest = { file, fields, completion in
            server.patches.append((file.recordId, fields))
            completion(server.patchSucceeds)
        }
        viewModel.updateV1Request = { params, completion in
            server.v1Locations.append((params.files.map(\.recordId), params.location))
            completion(true)
        }
        return viewModel
    }

    /// Starts a save and waits for its answer, for at most five seconds, letting queued main-queue work run.
    private func result(of start: (@escaping (Bool) -> Void) -> Void) async -> Bool? {
        var outcome: Bool?
        start { outcome = $0 }
        let deadline = Date().addingTimeInterval(5)
        while outcome == nil, Date() < deadline {
            await Task.yield()
        }
        return outcome
    }
}
