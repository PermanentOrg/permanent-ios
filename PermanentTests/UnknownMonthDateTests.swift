//
//  UnknownMonthDateTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 20.11.2026.
//

import Foundation
import SwiftUI
import Testing
@testable import Permanent

/// A year with an unknown month or day (`1985-XX`, `1985-XX-XX`) is a normal date of that year: it opens the
/// date sheet on the year, saves the year, and shows as the year everywhere.
struct UnknownMonthDateTests {
    static let unknownMonthValues = ["1985-XX", "1985-XX-XX"]
    private let legacy = "2023-08-15T00:00:00.000Z"

    @Test("It stays a complex value but is not web-only", arguments: unknownMonthValues)
    func isNotWebOnly(displayTime: String) {
        #expect(DateUtils.isComplexDate(displayTime))
        #expect(!DateUtils.isWebOnlyDate(displayTime))
        #expect(!WebOnlyDateMessage.applies(to: displayTime))
        #expect(DateUtils.yearOfUnknownMonth(displayTime) == "1985")
    }

    @Test("Other unknown digits stay web-only", arguments: ["1985-10-XX", "1985-XX~", "1985-XX-03", "198X-XX", "1985-XX/1990"])
    func othersStayWebOnly(displayTime: String) {
        #expect(DateUtils.yearOfUnknownMonth(displayTime) == nil)
        #expect(DateUtils.isWebOnlyDate(displayTime))
    }

    @Test("The date sheet opens on the year and Save writes the year", arguments: unknownMonthValues)
    func sheetOpensOnTheYear(displayTime: String) {
        let entry = DateTimeEntry(displayTime: displayTime, legacy: legacy, onlyEDTF: false)
        #expect(entry.year == "1985")
        #expect(entry.month.isEmpty)
        #expect(entry.day.isEmpty)
        #expect(!entry.hasTime)
        #expect(entry.edtfString == "1985")
    }

    @Test("The list, the Info row and sorting read the year, with the edtf-date switch on and off",
          arguments: unknownMonthValues, [true, false])
    func readsAsTheYear(displayTime: String, onlyEDTF: Bool) {
        #expect(DateUtils.listDate(displayTime: displayTime, legacy: legacy, onlyEDTF: onlyEDTF) == "1985")
        #expect(DateUtils.infoRowDate(displayTime: displayTime, legacy: legacy, onlyEDTF: onlyEDTF) == "1985")
        #expect(DateUtils.date(fromDisplayTime: displayTime) != nil)
    }

    @Test("The list row shows the year with no Unspecified mark", arguments: unknownMonthValues)
    func listRowShowsTheYear(displayTime: String) {
        var file = FileModel.mockFile()
        file.displayTime = displayTime
        file.date = DateUtils.listDate(displayTime: displayTime, legacy: legacy)
        #expect(file.complexDate == nil)
        #expect(file.displayDateText == "1985")
        #expect(file.sizeAndDateForVoiceOver.hasSuffix("1985"))
    }

    @Test("The item menu's date row opens the date sheet", arguments: unknownMonthValues)
    @MainActor
    func menuOpensDateSheet(displayTime: String) {
        var file = FileModel.mockFile()
        file.displayTime = displayTime
        #expect(EditDateAndTimeView.menuDoor(for: file) {} is UIHostingController<EditDateAndTimeView>)
    }

    @Test("Edit Metadata counts only the web-only file", arguments: unknownMonthValues)
    @MainActor
    func batchCountsOnlyWebOnly(displayTime: String) {
        var unknownMonth = FileModel.mockFile()
        unknownMonth.displayTime = displayTime
        var approximate = FileModel.mockFile()
        approximate.displayTime = "1985-XX~"
        var exact = FileModel.mockFile()
        exact.displayTime = "2023-09-16"

        let viewModel = FilesMetadataViewModel(files: [])
        viewModel.selectedFiles = [unknownMonth, exact]
        #expect(!viewModel.hasWebOnlyDate)

        viewModel.selectedFiles = [unknownMonth, approximate, exact]
        #expect(viewModel.hasWebOnlyDate)
        #expect(WebOnlyDateMessage.message(for: viewModel.selectedFiles) == WebOnlyDateMessage.batchMessage(complexCount: 1, of: 3))
    }
}
