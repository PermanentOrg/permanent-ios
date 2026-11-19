//
//  ComplexDateTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 18.11.2026.
//

import Foundation
import SwiftUI
import Testing
@testable import Permanent

/// A `displayTime` that is set but is not one exact date: no screen shows a date for it, the old field never
/// stands in, and sorting treats it as no date.
struct ComplexDateTests {
    static let complexValues = [
        "1985/1990", "1985-06/1990", "../1990", "1985/..", "1985~", "1985?", "1985%", "198X", "1985-XX"
    ]
    private let legacy = "2023-08-15T00:00:00.000Z"

    @Test("Each complex example counts as complex", arguments: complexValues)
    func isComplex(displayTime: String) {
        #expect(DateUtils.isComplexDate(displayTime))
    }

    @Test("One exact date, an empty value and no value are not complex", arguments: [
        "1985", "1985-10", "1985-10-23", "1985-10-23T17:00:00", "1985-10-23T17:00:00Z", "1985-10-23T17:00:00+03:00", "", nil
    ] as [String?])
    func isNotComplex(displayTime: String?) {
        #expect(!DateUtils.isComplexDate(displayTime))
    }

    @Test("A complex date gives no exact date and never the old one, with the edtf-date switch on and off", arguments: complexValues, [true, false])
    func showsNoDate(displayTime: String, onlyEDTF: Bool) {
        #expect(DateUtils.listDate(displayTime: displayTime, legacy: legacy, onlyEDTF: onlyEDTF).isEmpty)
        #expect(DateUtils.infoRowDate(displayTime: displayTime, legacy: legacy, onlyEDTF: onlyEDTF) == nil)
        #expect(DateUtils.date(fromDisplayTime: displayTime) == nil)
        #expect(DateUtils.displayTimeParts(displayTime) == nil)
    }

    @Test("A list row shows a complex date as written on web", arguments: [
        ("1985~", "c. 1985"), ("1985/1990", "1985 — 1990"), ("../1990", "Before 1990"), ("198X", "1980s")
    ])
    func listRowShowsComplexDate(displayTime: String, expected: String) {
        var file = FileModel.mockFile()
        file.displayTime = displayTime
        file.createdDT = legacy
        #expect(file.displayDateText == expected)
        #expect(file.sizeAndDateForVoiceOver.hasSuffix(ComplexDateText(displayTime).voiceOverText))
    }

    @Test("A V1 search or Shares row reads the web date, with the edtf-date switch on and off", arguments: [true, false])
    func v1RowReadsWebDate(onlyEDTF: Bool) throws {
        let json = #"{ "displayName": "A", "recordId": 3, "displayDT": "2020-01-01T00:00:00", "displayTime": "1985~" }"#
        let item = try ItemVO.decoder.decode(ItemVO.self, from: Data(json.utf8))
        let file = FileModel(model: item, permissions: [.read], accessRole: .viewer, onlyEDTF: onlyEDTF)
        #expect(file.date.isEmpty)
        #expect(file.displayDateText == "c. 1985")

        let folderJSON = #"{ "displayName": "B", "folderId": 4, "displayDT": "2020-01-01T00:00:00", "displayTime": "1985/1990" }"#
        let folder = try JSONDecoder().decode(MinFolderVO.self, from: Data(folderJSON.utf8))
        let folderFile = FileModel(model: folder, permissions: [.read], accessRole: .viewer, onlyEDTF: onlyEDTF)
        #expect(folderFile.displayDateText == "1985 — 1990")
    }

    @Test("A complex date counts as set, so a failed save never retries through V1", arguments: complexValues)
    func countsAsSet(displayTime: String) {
        #expect(!DateUtils.showsLegacyDate(displayTimes: [displayTime]))
    }

    @Test("The date sheet opens empty for a complex date, never on the old field", arguments: complexValues)
    func sheetOpensEmpty(displayTime: String) {
        #expect(DateTimeEntry(displayTime: displayTime, legacy: legacy, onlyEDTF: false).isEmpty)
    }

    @Test("Sorting by date puts a complex date with the undated items, by its upload date", arguments: complexValues)
    func sortsAsNoDate(displayTime: String) {
        var exact = FileModel.mockFile()
        exact.name = "exact"
        exact.displayTime = "2010"
        var complex = FileModel.mockFile()
        complex.name = "complex"
        complex.displayTime = displayTime
        complex.createdDT = "2020-01-01T00:00:00.000Z"
        var undated = FileModel.mockFile()
        undated.name = "undated"
        undated.displayTime = nil
        undated.createdDT = "2019-01-01T00:00:00.000Z"

        let ascending = FilesViewModel.sorted([complex, undated, exact], by: .dateAscending).map(\.name)
        #expect(ascending == ["exact", "undated", "complex"])
    }

    @Test("The item menu's date row opens the message for a complex date", arguments: complexValues)
    @MainActor
    func menuOpensMessage(displayTime: String) {
        var file = FileModel.mockFile()
        file.displayTime = displayTime
        #expect(EditDateAndTimeView.menuDoor(for: file) {} is UIHostingController<WebOnlyDateMessage>)
    }

    @Test("The item menu's date row opens the date sheet for one exact date or none", arguments: ["1985-10-23", nil] as [String?])
    @MainActor
    func menuOpensDateSheet(displayTime: String?) {
        var file = FileModel.mockFile()
        file.displayTime = displayTime
        #expect(EditDateAndTimeView.menuDoor(for: file) {} is UIHostingController<EditDateAndTimeView>)
    }
}
