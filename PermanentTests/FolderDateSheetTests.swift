//
//  FolderDateSheetTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 23.11.2026.
//

import Foundation
import SwiftUI
import Testing
@testable import Permanent

/// The date sheet opened from a folder's menu: it reads and saves the folder through the Stela V2 folder route.
@MainActor
struct FolderDateSheetTests {
    private let ownArchiveId = 5

    /// Records each call the sheet makes and answers it at once.
    private final class FakeServer {
        var folderPatches: [(folderId: Int, fields: [String: Any])] = []
        var recordPatches: [Int] = []
        var v1Batches = 0
        var reads: [FileModel] = []
        var patchSucceeds = true
        var zone: String?
        var displayTime: String?
    }

    @Test("Save PATCHes the folder id with displayTime and the zone, never a record or V1")
    func savesThroughTheFolderRoute() async throws {
        let server = FakeServer()
        server.zone = "Europe/Bucharest"
        let viewModel = try sheet(for: folder(archiveId: ownArchiveId), server: server)

        viewModel.readZoneIfNeeded()
        await wait { !viewModel.isReadingRecord }
        #expect(server.reads.map(\.folderId) == [55])
        #expect(viewModel.entry.timeZoneIdentifier == "Europe/Bucharest")

        viewModel.entry = DateTimeEntry(displayTime: "1990-05-12T10:30:00", legacy: nil, timeZoneIdentifier: "Europe/Bucharest")
        await applyChanges(in: viewModel)

        #expect(viewModel.changesWereSaved)
        let patch = try #require(server.folderPatches.first)
        #expect(server.folderPatches.count == 1 && patch.folderId == 55)
        #expect(patch.fields["displayTime"] as? String == viewModel.entry.edtfString)
        #expect((patch.fields["location"] as? [String: Any])?["timezone"] as? String == "Europe/Bucharest")
        #expect(server.recordPatches.isEmpty && server.v1Batches == 0)
    }

    @Test("A folder shared from another archive also saves through the folder route")
    func sharedFolderSavesToo() async throws {
        let server = FakeServer()
        let viewModel = try sheet(for: folder(archiveId: 9), server: server)
        viewModel.entry = DateTimeEntry(displayTime: "1990-05-12", legacy: nil)

        await applyChanges(in: viewModel)

        #expect(viewModel.changesWereSaved)
        #expect(server.folderPatches.map(\.folderId) == [55])
        #expect(server.v1Batches == 0)
    }

    @Test("A failed folder PATCH shows the alert and never calls V1, which cannot save a folder")
    func failedPatchShowsTheAlert() async throws {
        let server = FakeServer()
        server.patchSucceeds = false
        let viewModel = try sheet(for: folder(archiveId: ownArchiveId), server: server)
        viewModel.entry = DateTimeEntry(displayTime: "1990-05-12", legacy: nil)

        await applyChanges(in: viewModel)

        #expect(viewModel.showAlert)
        #expect(!viewModel.changesWereSaved)
        #expect(server.v1Batches == 0)
    }

    @Test("A folder with a date the sheet cannot hold shows the web-only message and Save sends nothing")
    func complexFolderDateStaysAsItIs() async throws {
        let server = FakeServer()
        server.displayTime = "198X"
        let viewModel = try sheet(for: folder(archiveId: ownArchiveId), server: server)

        viewModel.readZoneIfNeeded()
        await wait { viewModel.showsWebOnlyDate }
        #expect(viewModel.showsWebOnlyDate)

        viewModel.entry = DateTimeEntry(displayTime: "2001-02-03", legacy: nil)
        await applyChanges(in: viewModel)
        #expect(server.folderPatches.isEmpty && server.v1Batches == 0)
    }

    @Test("A record still saves through the record route")
    func recordKeepsTheRecordRoute() async throws {
        let server = FakeServer()
        let viewModel = try sheet(for: item(#""type": "type.record.image", "recordId": "301", "archiveId": "5""#), server: server)
        viewModel.entry = DateTimeEntry(displayTime: "1990-05-12", legacy: nil)

        await applyChanges(in: viewModel)

        #expect(server.recordPatches == [301])
        #expect(server.folderPatches.isEmpty)
    }

    @Test("Only a folder with an id saves to Stela; a record keeps its own rule")
    func savesDateToStelaRule() throws {
        #expect(try folder(archiveId: 9).savesDateToStela(sessionArchiveId: ownArchiveId))
        let noId = try item(#""type": "type.folder.private""#)
        #expect(!noId.savesDateToStela(sessionArchiveId: ownArchiveId))
        let sharedRecord = try item(#""type": "type.record.image", "recordId": "303", "archiveId": "9""#)
        #expect(!sharedRecord.savesDateToStela(sessionArchiveId: ownArchiveId))
    }

    @Test("A 401 on the folder PATCH shows the save alert instead of a logout")
    func folderPatchIgnoresAuthErrors() {
        #expect(FolderV2Endpoint.patchFolder(folderId: "55", fields: ["displayTime": "1990-05-12"]).ignoreErrors)
    }

    // MARK: - Several items

    @Test("Several items with folders save each one through its own route, with the same date")
    func selectionSavesEachItem() async throws {
        let server = FakeServer()
        let items = [try record(id: 301, archiveId: ownArchiveId), try folder(id: 55, archiveId: ownArchiveId),
                     try folder(id: 56, archiveId: ownArchiveId)]
        let viewModel = sheet(for: items, server: server)
        viewModel.entry = DateTimeEntry(displayTime: "1990-05-12", legacy: nil)

        await applyChanges(in: viewModel)

        #expect(viewModel.changesWereSaved)
        #expect(server.folderPatches.map(\.folderId) == [55, 56])
        #expect(server.folderPatches.allSatisfy { $0.fields["displayTime"] as? String == "1990-05-12" })
        #expect(server.recordPatches == [301])
        #expect(server.v1Batches == 0)
    }

    @Test("An untouched selection closes without a request")
    func untouchedSelectionSendsNothing() throws {
        let items = [try folder(id: 55, archiveId: ownArchiveId), try folder(id: 56, archiveId: ownArchiveId)]
        let viewModel = sheet(for: items, server: FakeServer())

        #expect(viewModel.closesWithoutSaving)
    }

    @Test("A selection with a complex date opens the counted message, not the date sheet")
    func selectionWithComplexDateOpensMessage() throws {
        let unknown = try item(#""type": "type.folder.private", "folderId": "55", "archiveId": "5", "displayTime": "XXXX-XX-XX""#)
        let approximate = try item(#""type": "type.record.image", "recordId": "302", "archiveId": "5", "displayTime": "2025~""#)
        let exact = try item(#""type": "type.record.image", "recordId": "301", "archiveId": "5", "displayTime": "2026-11-18""#)

        let door = EditDateAndTimeView.menuDoor(for: [unknown, exact, approximate]) {}

        let message = try #require(door as? UIHostingController<WebOnlyDateMessage>)
        #expect(message.rootView.message == WebOnlyDateMessage.batchMessage(complexCount: 2, of: 3))
        #expect(EditDateAndTimeView.menuDoor(for: [exact, try folder(archiveId: 5)]) {} is UIHostingController<EditDateAndTimeView>)
    }

    enum Selection: String, CaseIterable, Sendable {
        case fileAndFolders, foldersOnly, filesOnly, oneFolder, folderAndSharedFile, folderWithoutEdit
    }

    @Test("With the folder date flag on, a selection with a folder gets the date row when every item can save to Stela; off, never",
          arguments: Selection.allCases)
    func selectionDateRow(_ selection: Selection) throws {
        let own = ownArchiveId
        let items: [FileModel]
        switch selection {
        case .fileAndFolders: items = [try record(id: 301, archiveId: own), try folder(id: 55, archiveId: own), try folder(id: 56, archiveId: 9)]
        case .foldersOnly: items = [try folder(id: 55, archiveId: own), try folder(id: 56, archiveId: own)]
        case .filesOnly: items = [try record(id: 301, archiveId: own), try record(id: 302, archiveId: own)]
        case .oneFolder: items = [try folder(id: 55, archiveId: own)]
        case .folderAndSharedFile: items = [try folder(id: 55, archiveId: own), try record(id: 303, archiveId: 9)]
        case .folderWithoutEdit: items = [try folder(id: 55, archiveId: own), try folder(id: 56, archiveId: own, canEdit: false)]
        }
        let shows = [Selection.fileAndFolders, .foldersOnly].contains(selection)

        #expect(FileMenuItems.selectionAdjustsDate(items, sessionArchiveId: own, editsFolderDates: true) == shows)
        #expect(!FileMenuItems.selectionAdjustsDate(items, sessionArchiveId: own, editsFolderDates: false))
    }

    // MARK: - Helpers

    private func folder(id: Int = 55, archiveId: Int, canEdit: Bool = true) throws -> FileModel {
        let file = try item(#""type": "type.folder.private", "folderId": "\#(id)", "archiveId": "\#(archiveId)""#, canEdit: canEdit)
        try #require(file.type.isFolder)
        return file
    }

    private func record(id: Int, archiveId: Int) throws -> FileModel {
        try item(#""type": "type.record.image", "recordId": "\#(id)", "archiveId": "\#(archiveId)""#)
    }

    private func item(_ fields: String, canEdit: Bool = true) throws -> FileModel {
        let json = #"{ "items": [ { "folderLinkId": "900", \#(fields) } ] }"#
        let response = try FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: Data(json.utf8))
        let item = try #require(response.items?.first)
        return FileModel(model: item, permissions: canEdit ? [.read, .edit] : [.read], accessRole: canEdit ? .editor : .viewer)
    }

    /// One item opened from a list, with the session, the read and both PATCH routes faked.
    private func sheet(for file: FileModel, server: FakeServer) -> EditDateAndTimeViewModel {
        sheet(for: [file], server: server)
    }

    /// Several items opened from the selection menu, faked the same way.
    private func sheet(for files: [FileModel], server: FakeServer) -> EditDateAndTimeViewModel {
        let viewModel = EditDateAndTimeViewModel(selectedFiles: files, hasUpdates: .constant(false))
        let archiveId = ownArchiveId
        viewModel.sessionArchiveId = { archiveId }
        viewModel.fetchRecordZone = { file, completion in
            server.reads.append(file)
            completion((zone: server.zone, displayTime: server.displayTime))
        }
        viewModel.patchFolderRequest = { file, fields, completion in
            server.folderPatches.append((file.folderId, fields))
            completion(server.patchSucceeds)
        }
        viewModel.patchRecordRequest = { file, _, completion in
            server.recordPatches.append(file.recordId)
            completion(server.patchSucceeds)
        }
        viewModel.updateV1Request = { _, completion in
            server.v1Batches += 1
            completion(true)
        }
        return viewModel
    }

    private func applyChanges(in viewModel: EditDateAndTimeViewModel) async {
        viewModel.applyChanges()
        await wait { !viewModel.isLoading }
    }

    /// Waits until `done` holds, for at most five seconds, letting queued main-thread work run.
    private func wait(until done: () -> Bool) async {
        let deadline = Date().addingTimeInterval(5)
        while !done(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}
