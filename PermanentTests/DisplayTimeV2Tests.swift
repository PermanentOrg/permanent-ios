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
/// read, and saved or cleared by the details and batch date screens, with the V1 call as the failsafe.
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

    @Test("With the server's edtf-date switch on, the list and the Info row show displayTime only")
    func onlyEDTFLeavesTheOldDateOut() {
        let legacy = "2023-08-15T00:00:00.000Z"

        #expect(DateUtils.listDate(displayTime: nil, legacy: legacy, onlyEDTF: true) == "-")
        #expect(DateUtils.listDate(displayTime: nil, legacy: legacy, onlyEDTF: false) == "2023-08-15")
        #expect(DateUtils.listDate(displayTime: "1985-10", legacy: legacy, onlyEDTF: true) == "1985-10")
        #expect(DateUtils.infoRowDate(displayTime: nil, legacy: legacy, onlyEDTF: true) == nil)
        #expect(DateUtils.infoRowDate(displayTime: nil, legacy: legacy, timeZone: TimeZone(secondsFromGMT: 0) ?? .current, onlyEDTF: false) == "August 15, 2023 • 12AM")
        #expect(DateUtils.infoRowDate(displayTime: "1985", legacy: legacy, onlyEDTF: true) == "1985")
        #expect(DateUtils.shownLegacy(legacy, onlyEDTF: true) == nil)
        #expect(DateUtils.shownLegacy(legacy, onlyEDTF: false) == legacy)
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
        #expect(server.patches.allSatisfy { $0.fields as? [String: String] == ["displayTime": "2001-02-03T09:30:00"] }, "the clock as typed, no offset")
        #expect(server.v1Batches.isEmpty)
    }

    @MainActor
    @Test("A year alone saves as the year")
    func batchSaveYearAlone() async throws {
        let files = try [child(#""recordId": "301", "archiveId": "5""#)]
        let server = FakeServer(patchSucceeds: true)
        let viewModel = batchViewModel(files: files, server: server)
        viewModel.entry = DateTimeEntry(displayTime: "1999", legacy: nil)

        await applyChanges(in: viewModel)

        #expect(viewModel.changesWereSaved)
        #expect(server.patches.first?.fields as? [String: String] == ["displayTime": "1999"])
    }

    @MainActor
    @Test("A clear sends displayTime null and makes no V1 call")
    func batchClearSendsNull() async throws {
        let files = try [child(#""recordId": "301", "archiveId": "5""#), child(#""recordId": "302", "archiveId": "5", "displayTime": "1985""#)]
        let server = FakeServer(patchSucceeds: true)
        let viewModel = batchViewModel(files: files, server: server)
        viewModel.entry.clear()

        await applyChanges(in: viewModel)

        #expect(viewModel.changesWereSaved)
        #expect(server.patches.map(\.recordId) == [301, 302])
        #expect(server.patches.allSatisfy { $0.fields["displayTime"] is NSNull })
        #expect(server.v1Batches.isEmpty)
        let body = try #require(RecordV2Endpoint.patchRecord(recordId: "301", fields: ["displayTime": NSNull()]).bodyData)
        #expect(String(data: body, encoding: .utf8) == #"{"displayTime":null}"#)
    }

    @MainActor
    @Test("A failed clear shows the alert and skips V1")
    func batchClearFailureSkipsV1() async throws {
        let files = try [child(#""recordId": "301", "archiveId": "5""#)]
        let server = FakeServer(patchSucceeds: false)
        let viewModel = batchViewModel(files: files, server: server)
        viewModel.entry.clear()

        await applyChanges(in: viewModel)

        #expect(viewModel.showAlert)
        #expect(!viewModel.changesWereSaved)
        #expect(server.v1Batches.isEmpty)
    }

    @MainActor
    @Test("A clear of a shared record, which only V1 saves, shows the alert and sends nothing")
    func batchClearOfSharedRecordSendsNothing() async throws {
        let files = try [child(#""recordId": "301", "archiveId": "9""#)]
        let server = FakeServer(patchSucceeds: true)
        let viewModel = batchViewModel(files: files, server: server)
        viewModel.entry.clear()

        await applyChanges(in: viewModel)

        #expect(viewModel.showAlert)
        #expect(server.patches.isEmpty)
        #expect(server.v1Batches.isEmpty)
    }

    // MARK: - Save needs a date

    @MainActor
    @Test("An undated record opens with Save off")
    func undatedRecordCannotSave() throws {
        let undated = try child(#""recordId": "301", "archiveId": "5""#)
        let viewModel = EditDateAndTimeViewModel(selectedFiles: [undated], hasUpdates: .constant(false))

        #expect(viewModel.entry.isEmpty)
        #expect(!viewModel.canSave)
    }

    @MainActor
    @Test("A batch whose files have different dates opens empty with Save off")
    func mixedDateBatchCannotSave() throws {
        let files = try [
            child(#""recordId": "301", "archiveId": "5", "displayTime": "1985-10""#),
            child(#""recordId": "302", "archiveId": "5", "displayTime": "2001-02-03""#)
        ]
        let viewModel = EditDateAndTimeViewModel(selectedFiles: files, hasUpdates: .constant(false))

        #expect(viewModel.entry.isEmpty)
        #expect(!viewModel.canSave)
    }

    @MainActor
    @Test("A year alone turns Save on")
    func yearAloneCanSave() throws {
        let undated = try child(#""recordId": "301", "archiveId": "5""#)
        let viewModel = EditDateAndTimeViewModel(selectedFiles: [undated], hasUpdates: .constant(false))

        viewModel.entry.year = "1999"

        #expect(viewModel.canSave)
        #expect(viewModel.entry.edtfString == "1999")
    }

    @MainActor
    @Test("A dated entry emptied from the last field to the first turns Save off only with the last field")
    func emptiedFieldByFieldCannotSave() throws {
        let dated = try child(#""recordId": "301", "archiveId": "5", "displayTime": "2001-02-03T09:30:15""#)
        let viewModel = EditDateAndTimeViewModel(selectedFiles: [dated], hasUpdates: .constant(false))
        #expect(viewModel.canSave)

        let fields: [DateTimeEntry.Field] = [.second, .minute, .hour, .day, .month, .year]
        for field in fields.dropLast() {
            viewModel.entry[field] = ""
            #expect(viewModel.canSave, "Save stays on after \(field.label) is emptied")
        }
        if let last = fields.last { viewModel.entry[last] = "" }

        #expect(!viewModel.canSave)
        #expect(viewModel.saveBlockedReason == "Enter a date first")
    }

    @MainActor
    @Test(
        "A time needs a year, a month and a day before Save turns on, as on web",
        arguments: [
            ("", "", "", "09", false),
            ("1999", "", "", "09", false),
            ("1999", "10", "", "09", false),
            ("1999", "10", "23", "09", true),
            ("1999", "10", "", "", true)
        ]
    )
    func timeNeedsFullDate(year: String, month: String, day: String, hour: String, saves: Bool) throws {
        let undated = try child(#""recordId": "301", "archiveId": "5""#)
        let viewModel = EditDateAndTimeViewModel(selectedFiles: [undated], hasUpdates: .constant(false))

        viewModel.entry.year = year
        viewModel.entry.month = month
        viewModel.entry.day = day
        viewModel.entry.hour = hour

        #expect(viewModel.canSave == saves)
        #expect(viewModel.saveBlockedReason == (saves ? nil : "A complete date is required when time is provided."))
    }

    @MainActor
    @Test(
        "A later field needs the ones before it, and minutes need an hour",
        arguments: [
            ("", "10", "", "", "", "Add a year"),
            ("", "", "23", "", "", "Add a year"),
            ("1999", "", "23", "", "", "Add a month"),
            ("1999", "10", "23", "", "30", "Add an hour"),
            ("1999", "10", "23", "09", "30", nil)
        ] as [(String, String, String, String, String, String?)]
    )
    func laterFieldNeedsEarlierOnes(year: String, month: String, day: String, hour: String, minute: String, reason: String?) throws {
        let undated = try child(#""recordId": "301", "archiveId": "5""#)
        let viewModel = EditDateAndTimeViewModel(selectedFiles: [undated], hasUpdates: .constant(false))

        viewModel.entry.year = year
        viewModel.entry.month = month
        viewModel.entry.day = day
        viewModel.entry.hour = hour
        viewModel.entry.minute = minute

        #expect(viewModel.saveBlockedReason == reason)
        #expect(viewModel.canSave == (reason == nil))
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
        #expect(server.v1Batches.first?.allSatisfy { $0.date == utcStamp(of: viewModel.entry.pickerDate()) } == true, "V1 keeps its UTC displayDT")
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

    @Test("The Edit screen's date section reads one saved date although the upload dates differ")
    func editScreenReadsTheSavedDateOfABatch() throws {
        let saved = try [
            child(#""recordId": "301", "displayDate": "2011-03-12T22:17:25.000Z", "displayTime": "1985-10-23T09:30:00+01:00""#),
            child(#""recordId": "302", "displayDate": "2012-08-09T02:52:11.000Z", "displayTime": "1985-10-23T09:30:00+01:00""#)
        ]
        var mixed = saved
        mixed[1].displayTime = nil

        #expect(!FilesMetadataViewModel(files: saved).haveDiffDate)
        #expect(FilesMetadataViewModel(files: mixed).haveDiffDate, "a file with no saved date shows its upload date")
    }

    // MARK: - Zone

    @MainActor
    @Test("A save with a time and a zone sends the zone's offset at that date in the string, and location.timezone")
    func zonedSaveSendsOffsetAndZone() async throws {
        let files = try [child(#""recordId": "301", "archiveId": "5""#), child(#""recordId": "302", "archiveId": "5""#)]
        let server = FakeServer(patchSucceeds: true)
        let viewModel = batchViewModel(files: files, server: server)
        viewModel.entry.timeZoneIdentifier = "America/New_York"

        await applyChanges(in: viewModel)

        #expect(viewModel.changesWereSaved)
        #expect(server.patches.map(\.recordId) == [301, 302])
        #expect(server.patches.allSatisfy { $0.fields["displayTime"] as? String == "2001-02-03T09:30:00-05:00" }, "the same zone on every record")
        #expect(server.patches.allSatisfy { $0.fields["location"] as? [String: String] == ["timezone": "America/New_York"] })
        let body = try #require(RecordV2Endpoint.patchRecord(recordId: "301", fields: viewModel.patchFields).bodyData)
        let sent = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(sent["displayTime"] as? String == "2001-02-03T09:30:00-05:00")
        #expect(sent["location"] as? [String: String] == ["timezone": "America/New_York"])
    }

    @MainActor
    @Test("A save that never touched the zone sends no location key, so no empty location row is made")
    func untouchedSaveSendsNoLocation() async throws {
        let files = try [child(#""recordId": "301", "archiveId": "5""#)]
        let server = FakeServer(patchSucceeds: true)
        let viewModel = batchViewModel(files: files, server: server)

        await applyChanges(in: viewModel)

        #expect(server.patches.first?.fields as? [String: String] == ["displayTime": "2001-02-03T09:30:00"])
        #expect(server.patches.first?.fields["location"] == nil)
    }

    @MainActor
    @Test("Unsetting the zone the sheet opened with sends location.timezone null")
    func unsetZoneSendsNull() async throws {
        let files = try [child(#""recordId": "301", "archiveId": "5""#)]
        let server = FakeServer(patchSucceeds: true)
        let viewModel = batchViewModel(files: files, server: server, recordZone: .known("Europe/Paris"))
        #expect(viewModel.openingZone == "Europe/Paris")
        #expect(viewModel.entry.timeZoneIdentifier == "Europe/Paris")
        viewModel.entry.timeZoneIdentifier = nil

        await applyChanges(in: viewModel)

        let fields = try #require(server.patches.first?.fields)
        #expect(fields["displayTime"] as? String == "2001-02-03T09:30:00")
        #expect((fields["location"] as? [String: Any])?["timezone"] is NSNull)
    }

    @MainActor
    @Test("A clear sends displayTime null and location.timezone null")
    func clearSendsBothNulls() async throws {
        let files = try [child(#""recordId": "301", "archiveId": "5""#)]
        let server = FakeServer(patchSucceeds: true)
        let viewModel = batchViewModel(files: files, server: server)
        viewModel.entry.clear()

        await applyChanges(in: viewModel)

        let fields = try #require(server.patches.first?.fields)
        #expect(fields["displayTime"] is NSNull)
        #expect((fields["location"] as? [String: Any])?["timezone"] is NSNull)
    }

    @MainActor
    @Test("The V1 retry ignores the zone and keeps its UTC displayDT")
    func v1RetryIgnoresTheZone() async throws {
        let files = try [child(#""recordId": "301", "archiveId": "5""#)]
        let server = FakeServer(patchSucceeds: false)
        let viewModel = batchViewModel(files: files, server: server)
        viewModel.entry.timeZoneIdentifier = "Europe/Paris"

        await applyChanges(in: viewModel)

        #expect(viewModel.changesWereSaved)
        #expect(server.patches.first?.fields["location"] as? [String: String] == ["timezone": "Europe/Paris"])
        #expect(server.v1Batches.first?.allSatisfy { $0.date == utcStamp(of: viewModel.entry.pickerDate()) } == true)
    }

    @MainActor
    @Test("A list door shows no zone until its record is read; a record with an offset and no zone then takes web's guess")
    func offsetOnlyRecordOpensOnTheGuess() async throws {
        let file = try child(#""recordId": "301", "archiveId": "5", "displayTime": "1985-10-23T17:00:00+01:00""#)
        let server = FakeServer(patchSucceeds: true)
        let viewModel = listDoorViewModel(file: file, server: server)

        #expect(viewModel.entry.timeZoneIdentifier == nil)
        #expect(viewModel.openingZone == nil)
        viewModel.readZoneIfNeeded()
        await wait { viewModel.entry.timeZoneIdentifier != nil }

        #expect(server.zoneReads == [301])
        #expect(viewModel.entry.timeZoneIdentifier == "Africa/Algiers")
        #expect(viewModel.openingZone == "Africa/Algiers")
        #expect(viewModel.patchFields["displayTime"] as? String == "1985-10-23T17:00:00+01:00")
        #expect(viewModel.patchFields["location"] as? [String: String] == ["timezone": "Africa/Algiers"])
        #expect(EditDateAndTimeViewModel(selectedFiles: [file], hasUpdates: .constant(false), recordZone: .known("Europe/Paris")).entry.timeZoneIdentifier == "Europe/Paris")
    }

    @MainActor
    @Test("The Info door seeds the sheet from the record it read; the row the screen opened with is stale after a save")
    func infoDoorSeedsTheSheetFromTheRecord() throws {
        let listRow = try child(#""recordId": "301", "archiveId": "5", "displayName": "B", "displayTime": "2025-07-24T21:36:00""#)
        let json = """
        { "data": {
            "recordId": "301", "archiveId": "5", "displayName": "B", "type": "type.record.image",
            "displayDate": "2023-08-15T00:00:00.000Z", "displayTime": "1985-10-23T17:00:00+01:00",
            "location": { "id": "7", "timezone": "Europe/Paris" }
        } }
        """
        let data = try #require(try RecordV2Response.decoder.decode(RecordV2Response.self, from: Data(json.utf8)).data)
        let record = try #require((JSONHelper.decoding(from: data.toRecordVOPayload(), with: RecordVO.decoder) as RecordVO?)?.recordVO)

        let infoDoor = EditDateAndTimeViewModel(file: listRow, record: record, hasUpdates: .constant(false))
        let listDoor = EditDateAndTimeViewModel(file: listRow, record: nil, hasUpdates: .constant(false))

        #expect(infoDoor.entry.edtfString == "1985-10-23T17:00:00+01:00")
        #expect(infoDoor.entry.timeZoneIdentifier == "Europe/Paris")
        #expect(infoDoor.openingZone == "Europe/Paris")
        #expect(infoDoor.selectedFiles.first?.name == listRow.name, "only the date fields come from the record")
        #expect(infoDoor.selectedFiles.first?.createdDT == "2023-08-15T00:00:00.000Z")
        #expect(infoDoor.selectedFiles.first?.date == "1985-10-23")
        #expect(listDoor.entry.edtfString == "2025-07-24T21:36:00")
        #expect(listDoor.entry.timeZoneIdentifier == nil, "a list door reads the record itself")
    }

    @MainActor
    @Test("A batch opens with no zone, and a shared record's list door on web's guess at once, with no record read")
    func guessWithoutAReadOpensAtOnce() throws {
        let file = try child(#""recordId": "301", "archiveId": "5", "displayTime": "1985-10-23T17:00:00+01:00""#)
        let other = try child(#""recordId": "302", "archiveId": "5", "displayTime": "1985-10-23T17:00:00+01:00""#)
        let shared = try child(#""recordId": "303", "archiveId": "9", "displayTime": "1985-10-23T17:00:00+01:00""#)
        let server = FakeServer(patchSucceeds: true)
        let batch = EditDateAndTimeViewModel(selectedFiles: [file, other], hasUpdates: .constant(false))
        let sharedDoor = listDoorViewModel(file: shared, server: server)

        #expect(batch.entry.timeZoneIdentifier == nil)
        #expect(sharedDoor.entry.timeZoneIdentifier == nil)
        sharedDoor.readZoneIfNeeded()

        #expect(server.zoneReads.isEmpty)
        #expect(sharedDoor.entry.timeZoneIdentifier == "Africa/Algiers")
        #expect(sharedDoor.openingZone == "Africa/Algiers")
    }

    @MainActor
    @Test("A list door reads one record's zone once; the Info door and a batch do not read")
    func oneFileReadsTheZoneOnce() async throws {
        let file = try child(#""recordId": "301", "archiveId": "5", "displayTime": "1985-10-23T17:00:00""#)
        let other = try child(#""recordId": "302", "archiveId": "5""#)
        let server = FakeServer(patchSucceeds: true)
        server.zone = "Europe/Paris"
        let listDoor = batchViewModel(files: [file], server: server)
        let infoDoor = batchViewModel(files: [file], server: server, recordZone: .known(nil))
        let batch = batchViewModel(files: [file, other], server: server)

        #expect(listDoor.entry.timeZoneIdentifier == nil)
        listDoor.readZoneIfNeeded()
        listDoor.readZoneIfNeeded()
        infoDoor.readZoneIfNeeded()
        batch.readZoneIfNeeded()
        await wait { listDoor.entry.timeZoneIdentifier != nil }

        #expect(server.zoneReads == [301])
        #expect(listDoor.entry.timeZoneIdentifier == "Europe/Paris")
        #expect(listDoor.openingZone == "Europe/Paris")
        #expect(listDoor.patchFields["location"] as? [String: String] == ["timezone": "Europe/Paris"])
        #expect(infoDoor.entry.timeZoneIdentifier == nil)
        #expect(batch.entry.timeZoneIdentifier == nil)
    }

    @MainActor
    @Test("A zone chosen before the read lands is kept, and the record's zone still counts as the opening one")
    func chosenZoneSurvivesTheRead() async throws {
        let file = try child(#""recordId": "301", "archiveId": "5", "displayTime": "1985-10-23T17:00:00""#)
        let server = FakeServer(patchSucceeds: true)
        server.zone = "Europe/Paris"
        server.holdsZoneReads = true
        let viewModel = batchViewModel(files: [file], server: server)

        viewModel.readZoneIfNeeded()
        viewModel.entry.timeZoneIdentifier = "Asia/Tokyo"
        server.answerHeldZoneReads()
        await wait { viewModel.openingZone == "Europe/Paris" }

        #expect(viewModel.entry.timeZoneIdentifier == "Asia/Tokyo")
        #expect(viewModel.openingZone == "Europe/Paris")
    }

    // MARK: - Zones on several files

    @MainActor
    @Test("Several files that share a zone open on it, and a new day saves it back with its offset")
    func sharedZoneOpensAndSaves() async throws {
        let server = FakeServer(patchSucceeds: true)
        let viewModel = try newYorkBatch(server: server, recordZone: .known("America/New_York"))

        #expect(viewModel.entry.timeZoneIdentifier == "America/New_York")
        viewModel.entry.day = "13"
        await applyChanges(in: viewModel)

        #expect(server.patches.map(\.recordId) == [301, 302])
        for patch in server.patches {
            #expect(patch.fields["displayTime"] as? String == "1990-05-13T10:30:00-04:00")
            #expect(patch.fields["location"] as? [String: String] == ["timezone": "America/New_York"])
        }
    }

    @MainActor
    @Test("Several files with no shared zone open with no zone, and a save sends no zone and no offset")
    func unsharedZonesKeepEachFilesZone() async throws {
        let server = FakeServer(patchSucceeds: true)
        let viewModel = try newYorkBatch(server: server, recordZone: .unknown)

        #expect(viewModel.entry.timeZoneIdentifier == nil, "a zone guessed from the offset would overwrite each file's own")
        viewModel.entry.day = "13"
        await applyChanges(in: viewModel)

        #expect(server.patches.count == 2)
        for patch in server.patches {
            #expect(patch.fields["displayTime"] as? String == "1990-05-13T10:30:00")
            #expect(patch.fields["location"] == nil)
        }
    }

    @MainActor
    @Test("An untouched Save on several files closes without a request; any change, a zone included, saves")
    func untouchedBatchSaveWritesNothing() throws {
        let server = FakeServer(patchSucceeds: true)
        let batch = try newYorkBatch(server: server, recordZone: .unknown)
        let file = try #require(batch.selectedFiles.first)
        let single = EditDateAndTimeViewModel(selectedFiles: [file], hasUpdates: .constant(false), recordZone: .known(nil))

        #expect(batch.closesWithoutSaving)
        #expect(!single.closesWithoutSaving, "one file keeps its own save path")
        batch.entry.timeZoneIdentifier = "Europe/London"
        #expect(!batch.closesWithoutSaving)
        batch.entry.timeZoneIdentifier = nil
        batch.entry.format = batch.entry.format.next
        #expect(!batch.closesWithoutSaving)
    }

    @Test("The batch screen hands the sheet a zone only when every record was read and all share it", arguments: [
        (["America/New_York", "America/New_York"], EditDateAndTimeViewModel.RecordZone.known("America/New_York")),
        (["America/New_York", "America/Toronto"], .unknown),
        (["America/New_York", nil], .unknown),
        ([nil, nil], .unknown),
        ([], .unknown)
    ] as [([String?], EditDateAndTimeViewModel.RecordZone)])
    func sharedZoneOfRecords(zones: [String?], expected: EditDateAndTimeViewModel.RecordZone) throws {
        let records = try zones.map { try record(zone: $0) }
        #expect(FilesMetadataViewModel.sharedZone(of: records) == expected)
    }

    @Test("A record that could not be read leaves the zone unknown")
    func unreadRecordLeavesTheZoneUnknown() throws {
        let read = try record(zone: "America/New_York")
        #expect(FilesMetadataViewModel.sharedZone(of: [read, nil]) == .unknown)
        #expect(FilesMetadataViewModel.sharedZone(of: [nil, read]) == .unknown)
    }

    // MARK: - Helpers

    /// Records each call the screens make and answers it at once, or holds a zone read until told.
    private final class FakeServer {
        let patchSucceeds: Bool
        var patches: [(recordId: Int, fields: [String: Any])] = []
        var v1Dates: [Date] = []
        var v1Batches: [[FileModel]] = []
        var zone: String?
        var zoneReads: [Int] = []
        var holdsZoneReads = false
        private var heldZoneReads: [(String?) -> Void] = []

        func readZone(of file: FileModel, completion: @escaping (String?) -> Void) {
            zoneReads.append(file.recordId)
            if holdsZoneReads {
                heldZoneReads.append(completion)
            } else {
                completion(zone)
            }
        }

        func answerHeldZoneReads() {
            let held = heldZoneReads
            heldZoneReads = []
            held.forEach { $0(zone) }
        }

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

    /// One file opened from a list, its entry as the file carries it, with the session and the zone read faked.
    @MainActor
    private func listDoorViewModel(file: FileModel, server: FakeServer) -> EditDateAndTimeViewModel {
        let viewModel = EditDateAndTimeViewModel(selectedFiles: [file], hasUpdates: .constant(false))
        let archiveId = ownArchiveId
        viewModel.sessionArchiveId = { archiveId }
        viewModel.fetchRecordZone = { file, completion in
            server.readZone(of: file, completion: completion)
        }
        return viewModel
    }

    @MainActor
    private func batchViewModel(
        files: [FileModel], server: FakeServer, recordZone: EditDateAndTimeViewModel.RecordZone = .unknown
    ) -> EditDateAndTimeViewModel {
        let viewModel = EditDateAndTimeViewModel(selectedFiles: files, hasUpdates: .constant(false), recordZone: recordZone)
        let archiveId = ownArchiveId
        viewModel.entry = DateTimeEntry(displayTime: "2001-02-03T09:30:00", legacy: nil, timeZoneIdentifier: viewModel.entry.timeZoneIdentifier)
        viewModel.sessionArchiveId = { archiveId }
        viewModel.fetchRecordZone = { file, completion in
            server.readZone(of: file, completion: completion)
        }
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

    /// Two own records saved as 10:30 in New York, as the batch screen hands them to the sheet.
    @MainActor
    private func newYorkBatch(server: FakeServer, recordZone: EditDateAndTimeViewModel.RecordZone) throws -> EditDateAndTimeViewModel {
        let files = try [301, 302].map { try child(#""recordId": "\#($0)", "archiveId": "5", "displayTime": "1990-05-12T10:30:00-04:00""#) }
        let viewModel = EditDateAndTimeViewModel(selectedFiles: files, hasUpdates: .constant(false), recordZone: recordZone)
        let archiveId = ownArchiveId
        viewModel.sessionArchiveId = { archiveId }
        viewModel.patchRecordRequest = { file, fields, completion in
            server.patches.append((file.recordId, fields))
            completion(server.patchSucceeds)
        }
        return viewModel
    }

    private func record(zone: String?) throws -> RecordVOData {
        let location = zone.map { #", "location": { "id": "7", "timezone": "\#($0)" }"# } ?? ""
        let json = """
        { "data": { "recordId": "301", "archiveId": "5", "type": "type.record.image", \
        "displayTime": "1990-05-12T10:30:00-04:00"\(location) } }
        """
        let data = try #require(try RecordV2Response.decoder.decode(RecordV2Response.self, from: Data(json.utf8)).data)
        return try #require((JSONHelper.decoding(from: data.toRecordVOPayload(), with: RecordVO.decoder) as RecordVO?)?.recordVO)
    }

    @MainActor
    private func save(date: Date, in viewModel: FilePreviewViewModel, file: FileModel) async -> Bool? {
        var outcome: Bool?
        viewModel.update(file: file, name: nil, description: nil, date: date, location: nil) { outcome = $0 }
        await wait { outcome != nil }
        return outcome
    }

    /// The old field's stamp for a moment: the clock in UTC, as the V1 save writes it.
    private func utcStamp(of date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.string(from: date)
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
