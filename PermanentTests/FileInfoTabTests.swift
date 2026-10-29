//
//  FileInfoTabTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import Foundation
import Testing
import UIKit
@testable import Permanent

/// The Info tab's row list for each role, the Details list, the name and description save rules, and the Date row
/// after the date screen saves.
@MainActor
struct FileInfoTabTests {
    private typealias CellType = FileDetailsViewController.CellType
    private let ownArchiveId = 5

    // MARK: - Rows

    @Test("A member with the edit right gets the four rows, boxed, then the tags row")
    func editorRows() throws {
        let screen = try makeScreen(fields: #""displayName": "August_Hike_003""#, permissions: [.read, .edit])

        let rows = screen.infoRows()
        #expect(rows.map(\.kind) == [.name, .description, .date, .location])
        #expect(rows.allSatisfy { $0.style == .boxed })
        #expect(rows.map(\.isSet) == [true, false, false, false])
        #expect(cells(of: screen) == [.name, .description, .date, .location, .tags])
    }

    @Test("A set location puts the map right after its row")
    func editorRowsWithCoordinates() throws {
        let screen = try makeScreen(fields: #""displayName": "B", \#(locationJSON)"#, permissions: [.read, .edit])

        let location = try #require(screen.infoRows().first { $0.kind == .location })
        #expect(location.isSet)
        #expect(location.text.contains("Yamanakako"))
        #expect(cells(of: screen) == [.name, .description, .date, .location, .locationMap, .tags])
    }

    @Test("A member without the edit right sees only the rows that hold data, plain, name first")
    func viewerRows() throws {
        let nameOnly = try makeScreen(fields: #""displayName": "C""#, permissions: [.read])
        #expect(nameOnly.infoRows().map(\.kind) == [.name])
        #expect(nameOnly.infoRows().allSatisfy { $0.style == .plain })
        #expect(cells(of: nameOnly) == [.name])

        let nameAndDate = try makeScreen(fields: #""displayName": "C", "displayTime": "1985-10-23T17:00:00""#, permissions: [.read])
        #expect(nameAndDate.infoRows().map(\.kind) == [.name, .date])
        #expect(cells(of: nameAndDate) == [.name, .date])

        let nameAndPlace = try makeScreen(fields: #""displayName": "C", \#(locationJSON)"#, permissions: [.read])
        #expect(nameAndPlace.infoRows().map(\.kind) == [.name, .location])
        #expect(cells(of: nameAndPlace) == [.name, .location, .locationMap])

        let described = try makeScreen(fields: #""displayName": "C", "description": "Picnic""#, permissions: [.read])
        #expect(described.infoRows().map(\.kind) == [.name, .description])
    }

    @Test("The tags row shows a viewer only the tags the record has")
    func viewerTags() throws {
        let tagged = try makeScreen(fields: #""displayName": "C", "tags": [{ "tagId": "1", "name": "hike" }]"#, permissions: [.read])
        #expect(cells(of: tagged) == [.name, .tags])

        let untagged = try makeScreen(fields: #""displayName": "C", "tags": []"#, permissions: [.read])
        #expect(cells(of: untagged) == [.name])
    }

    @Test("The Details tab keeps its eight rows")
    func detailsRows() {
        #expect(FileDetailsViewController.detailsCells == [.uploaded, .lastModified, .created, .fileCreated, .size, .fileType, .originalFileName, .originalFileType])
    }

    @Test("Before the record arrives, an editor already sees the four boxed rows with the file's name")
    func rowsBeforeTheRecordArrives() {
        let file = FileModel(name: "Pending.jpg", recordId: 42, folderLinkId: 7, archiveNbr: "0005-0000", type: "type.record.image", permissions: [.read, .edit])
        let viewModel = OfflinePreviewViewModel(file: file)

        #expect(viewModel.infoRows().map(\.text).first == "Pending.jpg")
        #expect(viewModel.infoRows().count == 4)
    }

    // MARK: - Saving

    @Test("An empty or unchanged name sends nothing and answers false")
    func nameRevertRules() async throws {
        let server = FakeServer(patchSucceeds: true)
        let screen = try makeScreen(fields: #""displayName": "August_Hike_003""#, permissions: [.read, .edit], server: server)

        let emptyName = await save(name: "", in: screen)
        #expect(emptyName == false)
        let sameName = await save(name: "August_Hike_003", in: screen)
        #expect(sameName == false)
        #expect(server.patches.isEmpty)
        #expect(screen.name == "August_Hike_003")
    }

    @Test("A new name goes out as displayName and answers true")
    func newNameIsSent() async throws {
        let server = FakeServer(patchSucceeds: true)
        let screen = try makeScreen(fields: #""displayName": "August_Hike_003""#, permissions: [.read, .edit], server: server)

        let renamed = await save(name: "A renamed", in: screen)
        #expect(renamed == true)
        #expect(server.patches.map(\.recordId) == [301])
        #expect(server.patches.first?.fields["displayName"] as? String == "A renamed")
        #expect(screen.name == "A renamed")
    }

    @Test("A failed save answers false and keeps the old name")
    func failedSave() async throws {
        let server = FakeServer(patchSucceeds: false)
        let screen = try makeScreen(fields: #""displayName": "August_Hike_003""#, permissions: [.read, .edit], server: server)

        let failed = await save(name: "A renamed", in: screen)
        #expect(failed == false)
        #expect(server.patches.count == 1, "the PATCH was tried")
        #expect(server.v1Names == ["A renamed"], "then the V1 failsafe")
        #expect(screen.name == "August_Hike_003")
    }

    @Test("A description follows the same rules")
    func descriptionRules() async throws {
        let server = FakeServer(patchSucceeds: true)
        let screen = try makeScreen(fields: #""displayName": "A", "description": "Picnic""#, permissions: [.read, .edit], server: server)

        let emptyDescription = await save(description: "", in: screen)
        #expect(emptyDescription == false)
        let sameDescription = await save(description: "Picnic", in: screen)
        #expect(sameDescription == false)
        #expect(server.patches.isEmpty)
        let newDescription = await save(description: "Lunch", in: screen)
        #expect(newDescription == true)
        #expect(server.patches.first?.fields["description"] as? String == "Lunch")
    }

    // MARK: - After the date screen

    @Test("After the date screen saves, the Date row shows the new date and the list is told to refresh")
    func dateRowAfterTheDateScreen() throws {
        let before = try record(#""displayName": "B", "displayTime": "1985-10-23T17:00:00""#)
        let after = try record(#""displayName": "B", "displayTime": "2001-02-03T09:30:00""#)
        let viewModel = RereadingPreviewViewModel(file: try file(from: before, permissions: [.read, .edit]))
        viewModel.recordVO = before
        viewModel.nextRecord = after
        let details = try #require(UIViewController.create(withIdentifier: .fileDetailsOnTap, from: .main) as? FileDetailsViewController)
        details.file = viewModel.file
        details.viewModel = viewModel
        let navigation = FilePreviewNavigationController(rootViewController: details)
        navigation.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        navigation.view.layoutIfNeeded()
        details.view.layoutIfNeeded()
        #expect(details.infoRows.first { $0.kind == .date }?.text == "October 23, 1985 • 5PM")

        details.dateScreenDidClose(saved: true)

        #expect(details.infoRows.first { $0.kind == .date }?.text == "February 3, 2001 • 9:30 AM")
        #expect(navigation.hasChanges)
    }

    // MARK: - Helpers

    private let locationJSON = #""location": { "id": "7", "name": "Yamanakako", "city": "Yamanashi", "country": "Japan", "latitude": 35.41, "longitude": 138.87 }"#

    /// A record through the real V2 bridge, as the screen receives it.
    private func record(_ fields: String) throws -> RecordVO {
        let json = """
        { "data": { "recordId": "301", "archiveId": "\(ownArchiveId)", "type": "type.record.image", "folderLinkId": "900", \(fields) } }
        """
        let data = try #require(try RecordV2Response.decoder.decode(RecordV2Response.self, from: Data(json.utf8)).data)
        return try #require(JSONHelper.decoding(from: data.toRecordVOPayload(), with: RecordVO.decoder) as RecordVO?)
    }

    private func file(from record: RecordVO, permissions: [Permission]) throws -> FileModel {
        let data = try #require(record.recordVO)
        return FileModel(model: data, permissions: permissions, accessRole: permissions.contains(.edit) ? .editor : .viewer)
    }

    private func makeScreen(fields: String, permissions: [Permission], server: FakeServer? = nil) throws -> FilePreviewViewModel {
        let recordVO = try record(fields)
        let viewModel = OfflinePreviewViewModel(file: try file(from: recordVO, permissions: permissions))
        viewModel.recordVO = recordVO
        let archiveId = ownArchiveId
        viewModel.sessionArchiveId = { archiveId }
        if let server {
            viewModel.patchRecordRequest = { recordId, fields, completion in
                server.patches.append((recordId, fields))
                completion(server.patchSucceeds)
            }
            viewModel.updateV1Request = { params, completion in
                if let name = params.name { server.v1Names.append(name) }
                completion(false)
            }
        }
        return viewModel
    }

    private func cells(of viewModel: FilePreviewViewModel) -> [CellType] {
        FileDetailsViewController.infoCells(rows: viewModel.infoRows(), hasMap: viewModel.infoTabHasMap, hasTags: viewModel.infoTabHasTags)
    }

    private func save(name: String, in viewModel: FilePreviewViewModel) async -> Bool? {
        var outcome: Bool?
        viewModel.saveName(name) { outcome = $0 }
        await wait { outcome != nil }
        return outcome
    }

    private func save(description: String, in viewModel: FilePreviewViewModel) async -> Bool? {
        var outcome: Bool?
        viewModel.saveDescription(description) { outcome = $0 }
        await wait { outcome != nil }
        return outcome
    }

    /// Lets queued main-thread work run until `done` holds, for at most five seconds.
    private func wait(until done: () -> Bool) async {
        let deadline = Date().addingTimeInterval(5)
        while !done(), Date() < deadline {
            await Task.yield()
        }
    }

    /// Records each call the screen makes and answers it at once.
    private final class FakeServer {
        let patchSucceeds: Bool
        var patches: [(recordId: Int, fields: [String: Any])] = []
        var v1Names: [String] = []

        init(patchSucceeds: Bool) {
            self.patchSucceeds = patchSucceeds
        }
    }

    /// The details view model with the record re-read after a save answered locally, not by the server.
    private class OfflinePreviewViewModel: FilePreviewViewModel {
        override func getRecord(file: FileModel, then handler: @escaping (RecordVO?) -> Void) {
            handler(nil)
        }
    }

    /// A re-read hands out the next record, as the server would after the date screen saved.
    private final class RereadingPreviewViewModel: OfflinePreviewViewModel {
        var nextRecord: RecordVO?

        override func getRecord(file: FileModel, then handler: @escaping (RecordVO?) -> Void) {
            if let nextRecord { recordVO = nextRecord }
            handler(recordVO)
        }
    }
}
