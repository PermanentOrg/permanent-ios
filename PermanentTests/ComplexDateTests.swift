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
        "1985/1990", "1985-06/1990", "../1990", "1985/..", "1985~", "1985?", "1985%", "198X", "1985-10-XX", "1985-XX~", "1985-XX-03"
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
        ("1985~", "c. 1985"), ("1985/1990", "1985 — 1990"), ("../1990", "Before 1990"), ("198X", "198X"), ("198X?", "198X ?")
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

    @Test("Web's Unknown date and an approximate year are web-only, and Unknown reads as such")
    func webUnknownAndApproximateAreWebOnly() {
        #expect(DateUtils.isWebOnlyDate("XXXX-XX-XX"))
        #expect(DateUtils.isWebOnlyDate("2025~"))
        var file = FileModel.mockFile()
        file.displayTime = "XXXX-XX-XX"
        #expect(file.displayDateText == "ComplexDateUnknown".localized())
    }

    // MARK: - The message panel

    @Test("A drag up never moves the panel, so it keeps its size; a drag down follows the finger",
          arguments: [(-300, 0), (-1, 0), (0, 0), (40, 40)] as [(CGFloat, CGFloat)])
    func panelNeverGrows(drag: CGFloat, offset: CGFloat) {
        #expect(WebOnlyDateMessage.offset(forDrag: drag) == offset)
    }

    @Test("Only a long or quick drag down closes the panel")
    func panelClosesOnALongDragDown() {
        #expect(!WebOnlyDateMessage.closes(afterDrag: -400, predicted: -800))
        #expect(!WebOnlyDateMessage.closes(afterDrag: 60, predicted: 100))
        #expect(WebOnlyDateMessage.closes(afterDrag: WebOnlyDateMessage.closingDrag + 1, predicted: 0))
        #expect(WebOnlyDateMessage.closes(afterDrag: 60, predicted: WebOnlyDateMessage.closingDrag * 2 + 1))
    }

    @Test("The card waits one card height below the bottom edge, so it moves in with the scrim; Reduce Motion only fades")
    func panelSlidesFromTheBottomEdge() {
        let slides = WebOnlyDateMessage.hiddenCard(reduceMotion: false, cardHeight: 420, bottomInset: 34)
        #expect(slides.offset == 454 && slides.opacity == 1)
        let fades = WebOnlyDateMessage.hiddenCard(reduceMotion: true, cardHeight: 420, bottomInset: 34)
        #expect(fades.offset == 0 && fades.opacity == 0)
    }

    @Test("Before its height is known the card stays clear, so it never shows in place before the slide")
    func panelHidesUntilMeasured() {
        let unmeasured = WebOnlyDateMessage.hiddenCard(reduceMotion: false, cardHeight: 0, bottomInset: 34)
        #expect(unmeasured.offset == 0 && unmeasured.opacity == 0)
    }

    @Test("UIKit shows the message over the whole screen, not as a system sheet that stretches")
    @MainActor
    func panelIsNotASystemSheet() {
        let controller = WebOnlyDateMessage.host(message: "message")
        #expect(controller.modalPresentationStyle == .overFullScreen)
        #expect(controller.sheetPresentationController == nil)
    }
}
