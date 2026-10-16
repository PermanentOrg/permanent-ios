//
//  DisplayTimeV2Tests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 16.10.2026.
//

import Foundation
import SwiftUI
import Testing
@testable import Permanent

/// `displayTime` through Stela V2: decoded from records, children and folders into what the screens
/// read, and saved by the details and batch date screens, with the V1 call as the failsafe.
struct DisplayTimeV2Tests {
    private let ownArchiveId = 5
    private let picked = Date(timeIntervalSince1970: 981_185_400) // 3 Feb 2001, 07:30 UTC

    // MARK: - Reading

    @Test("A record's displayTime survives the bridge and leads the list date")
    func recordDisplayTimeReachesFileModel() throws {
        let json = """
        { "data": {
            "recordId": "301", "archiveId": "5", "displayName": "B", "type": "type.record.image",
            "displayDate": "2023-08-15T00:00:00.000Z", "displayTime": "1985-10",
            "location": { "id": "7", "timezone": "Europe/Paris" }
        } }
        """
        let data = try #require(try RecordV2Response.decoder.decode(RecordV2Response.self, from: Data(json.utf8)).data)
        let recordVO = try #require(JSONHelper.decoding(from: data.toRecordVOPayload(), with: RecordVO.decoder) as RecordVO?)
        let record = try #require(recordVO.recordVO)
        let file = FileModel(model: record, permissions: [], accessRole: .viewer)

        #expect(data.location?.timezone == "Europe/Paris")
        #expect(record.displayTime == "1985-10")
        #expect(file.displayTime == "1985-10")
        #expect(file.date == "1985-10")
        #expect(file.createdDT == "2023-08-15T00:00:00.000Z", "the V1 failsafes still send the old field")
    }

    @Test("A child record and a child folder show displayTime first")
    func childrenShowDisplayTimeFirst() throws {
        let record = try child(#""recordId": "301", "displayDate": "2023-08-15T00:00:00.000Z", "displayTime": "2026-07-15T12:45:00""#)
        let folder = try child(#""folderId": "55", "displayTimestamp": "1980-01-01T00:00:00.000Z", "displayTime": "1990-05-01""#)

        #expect(record.date == "2026-07-15")
        #expect(record.displayTime == "2026-07-15T12:45:00")
        #expect(record.createdDT == "2023-08-15T00:00:00.000Z")
        #expect(folder.date == "1990-05-01")
        #expect(DateUtils.displayDate(from: folder.date) == "May. 1, 1990")
    }

    @Test("A child with no readable displayTime keeps the old date")
    func childWithoutReadableDisplayTimeKeepsOldDate() throws {
        let qualified = try child(#""recordId": "301", "displayDate": "2023-08-15T00:00:00.000Z", "displayTime": "1985~""#)
        let untouched = try child(#""recordId": "302", "displayDate": "2023-08-15T00:00:00.000Z""#)

        #expect(qualified.date == "2023-08-15")
        #expect(untouched.date == "2023-08-15")
        #expect(untouched.displayTime == nil)
    }

    @Test("A folder's own details show displayTime first, else displayTimestamp")
    func folderDetailsShowDisplayTimeFirst() throws {
        let json = """
        { "items": [
            { "folderId": "55", "displayTimestamp": "1980-01-01T00:00:00.000Z", "displayTime": "1990-05-01" },
            { "folderId": "56", "displayTimestamp": "1980-01-01T00:00:00.000Z" }
        ] }
        """
        let folders = try FolderV2Response.decoder.decode(FolderV2Response.self, from: Data(json.utf8)).items ?? []
        let files = folders.map { FileModel(model: $0, fallbackArchiveNo: "0005-0000", permissions: [], accessRole: .owner) }

        #expect(files.map(\.date) == ["1990-05-01", "1980-01-01"])
    }

    // MARK: - Request bodies

    @Test("The record and folder PATCH bodies carry displayTime only")
    func patchBodiesCarryDisplayTimeOnly() throws {
        let fields = DateUtils.displayTimeFields(for: picked)
        let expected = ["displayTime": DateUtils.displayTime(from: picked)]
        let record = RecordV2Endpoint.patchRecord(recordId: "301", fields: fields)
        let folder = FolderV2Endpoint.patchFolder(folderId: "55", fields: fields)

        #expect(try body(of: record.bodyData) == expected)
        #expect(try body(of: folder.bodyData) == expected)
        #expect(record.method == .patch && folder.method == .patch)
        #expect(record.customURL == "\(APIEnvironment.defaultEnv.apiServer)api/v2/records/301")
        #expect(folder.customURL == "\(APIEnvironment.defaultEnv.apiServer)api/v2/folders/55")
    }

    // MARK: - Details save

    @MainActor
    @Test("A details date save goes to V2 and makes no V1 call")
    func detailsSaveGoesToV2() async throws {
        let file = try child(#""recordId": "301", "archiveId": "5""#)
        let server = FakeServer(patchSucceeds: true)
        let viewModel = previewViewModel(file: file, server: server)

        let outcome = await save(date: picked, in: viewModel, file: file)

        #expect(outcome == true)
        #expect(server.patches.map(\.recordId) == [301])
        #expect(server.patches.first?.fields as? [String: String] == ["displayTime": DateUtils.displayTime(from: picked)])
        #expect(server.v1Dates.isEmpty)
    }

    @MainActor
    @Test("A failed V2 save of a record with no displayTime retries through V1 with the date")
    func detailsFailureWithoutDisplayTimeRetriesV1() async throws {
        let file = try child(#""recordId": "301", "archiveId": "5""#)
        let server = FakeServer(patchSucceeds: false)
        let viewModel = previewViewModel(file: file, server: server)

        let outcome = await save(date: picked, in: viewModel, file: file)

        #expect(outcome == true)
        #expect(server.patches.count == 1)
        #expect(server.v1Dates == [picked])
    }

    @MainActor
    @Test("A failed V2 save of a record with a displayTime reports the failure and skips V1")
    func detailsFailureWithDisplayTimeSkipsV1() async throws {
        let file = try child(#""recordId": "301", "archiveId": "5", "displayTime": "2026-07-15T12:45:00""#)
        let server = FakeServer(patchSucceeds: false)
        let viewModel = previewViewModel(file: file, server: server)

        let outcome = await save(date: picked, in: viewModel, file: file)

        #expect(outcome == false)
        #expect(server.v1Dates.isEmpty)
    }

    @MainActor
    @Test("A shared record's date keeps the V1 save, because the app reads it through V1")
    func detailsSharedRecordStaysOnV1() async throws {
        let file = try child(#""recordId": "301", "archiveId": "9""#)
        let server = FakeServer(patchSucceeds: true)
        let viewModel = previewViewModel(file: file, server: server)

        let outcome = await save(date: picked, in: viewModel, file: file)

        #expect(outcome == true)
        #expect(server.patches.isEmpty)
        #expect(server.v1Dates == [picked])
    }

    // MARK: - Batch save

    @MainActor
    @Test("A batch date save sends one V2 PATCH per record and no V1 batch")
    func batchSaveGoesToV2() async throws {
        let files = try [child(#""recordId": "301", "archiveId": "5""#), child(#""recordId": "302", "archiveId": "5""#)]
        let server = FakeServer(patchSucceeds: true)
        let viewModel = batchViewModel(files: files, server: server)

        await applyChanges(in: viewModel)

        #expect(viewModel.changesWereSaved)
        #expect(server.patches.map(\.recordId) == [301, 302])
        #expect(server.patches.allSatisfy { $0.fields as? [String: String] == ["displayTime": DateUtils.displayTime(from: picked)] })
        #expect(server.v1Batches.isEmpty)
    }

    @MainActor
    @Test("A failed batch with no displayTime retries the V1 batch")
    func batchFailureWithoutDisplayTimeRetriesV1() async throws {
        let files = try [child(#""recordId": "301", "archiveId": "5""#), child(#""recordId": "302", "archiveId": "5""#)]
        let server = FakeServer(patchSucceeds: false)
        let viewModel = batchViewModel(files: files, server: server)

        await applyChanges(in: viewModel)

        #expect(viewModel.changesWereSaved)
        #expect(server.v1Batches.map { $0.map(\.recordId) } == [[301, 302]])
        #expect(server.v1Batches.first?.allSatisfy { $0.date == "2001-02-03T07:30:00" } == true, "V1 keeps its UTC displayDT")
    }

    @MainActor
    @Test("A failed batch where a record has a displayTime shows the alert and skips V1")
    func batchFailureWithDisplayTimeSkipsV1() async throws {
        let files = try [child(#""recordId": "301", "archiveId": "5""#), child(#""recordId": "302", "archiveId": "5", "displayTime": "1985""#)]
        let server = FakeServer(patchSucceeds: false)
        let viewModel = batchViewModel(files: files, server: server)

        await applyChanges(in: viewModel)

        #expect(viewModel.showAlert)
        #expect(!viewModel.changesWereSaved)
        #expect(server.v1Batches.isEmpty)
    }

    @MainActor
    @Test("A batch with a shared record goes to V1 whole")
    func batchWithSharedRecordStaysOnV1() async throws {
        let files = try [child(#""recordId": "301", "archiveId": "5""#), child(#""recordId": "302", "archiveId": "9""#)]
        let server = FakeServer(patchSucceeds: true)
        let viewModel = batchViewModel(files: files, server: server)

        await applyChanges(in: viewModel)

        #expect(viewModel.changesWereSaved)
        #expect(server.patches.isEmpty)
        #expect(server.v1Batches.count == 1)
    }

    // MARK: - Helpers

    /// Records each call the screens make and answers it at once.
    private final class FakeServer {
        let patchSucceeds: Bool
        var patches: [(recordId: Int, fields: [String: Any])] = []
        var v1Dates: [Date] = []
        var v1Batches: [[FileModel]] = []

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

    private func child(_ fields: String) throws -> FileModel {
        let json = #"{ "items": [ { "type": "type.record.image", "folderLinkId": "900", \#(fields) } ] }"#
        let response = try FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: Data(json.utf8))
        let item = try #require(response.items?.first)
        return FileModel(model: item, permissions: [.read, .edit], accessRole: .editor)
    }

    private func body(of data: Data?) throws -> [String: String]? {
        try JSONSerialization.jsonObject(with: try #require(data)) as? [String: String]
    }

    @MainActor
    private func previewViewModel(file: FileModel, server: FakeServer) -> FilePreviewViewModel {
        let viewModel = OfflinePreviewViewModel(file: file)
        let archiveId = ownArchiveId
        viewModel.sessionArchiveId = { archiveId }
        viewModel.patchRecordRequest = { recordId, fields, completion in
            server.patches.append((recordId, fields))
            completion(server.patchSucceeds)
        }
        viewModel.updateV1Request = { params, completion in
            if let date = params.date { server.v1Dates.append(date) }
            completion(true)
        }
        return viewModel
    }

    @MainActor
    private func batchViewModel(files: [FileModel], server: FakeServer) -> EditDateAndTimeViewModel {
        let viewModel = EditDateAndTimeViewModel(selectedFiles: files, hasUpdates: .constant(false))
        let archiveId = ownArchiveId
        viewModel.selectedDate = picked
        viewModel.sessionArchiveId = { archiveId }
        viewModel.patchRecordRequest = { file, fields, completion in
            server.patches.append((file.recordId, fields))
            completion(server.patchSucceeds)
        }
        viewModel.updateV1Request = { files, completion in
            server.v1Batches.append(files)
            completion(true)
        }
        return viewModel
    }

    @MainActor
    private func save(date: Date, in viewModel: FilePreviewViewModel, file: FileModel) async -> Bool? {
        var outcome: Bool?
        viewModel.update(file: file, name: nil, description: nil, date: date, location: nil) { outcome = $0 }
        await wait { outcome != nil }
        return outcome
    }

    @MainActor
    private func applyChanges(in viewModel: EditDateAndTimeViewModel) async {
        viewModel.applyChanges()
        await wait { !viewModel.isLoading }
    }

    /// Waits until `done` holds, for at most five seconds, letting queued main-thread work run.
    @MainActor
    private func wait(until done: () -> Bool) async {
        let deadline = Date().addingTimeInterval(5)
        while !done(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}
