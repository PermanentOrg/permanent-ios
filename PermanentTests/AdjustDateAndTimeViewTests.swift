//
//  AdjustDateAndTimeViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import Foundation
import SwiftUI
import Testing
import UIKit
@testable import Permanent

/// The "Adjust date and time" sheet: it renders empty, prefilled and with each native picker, opens on the files'
/// common date, takes digits the way a member types them, and names its fields and pill for VoiceOver.
@MainActor
struct AdjustDateAndTimeViewTests {
    // MARK: - Rendering

    @Test("The sheet renders empty for an undated record")
    func rendersEmpty() throws {
        let viewModel = try viewModel(for: [child(#""recordId": "301", "archiveId": "5""#)])

        let host = render(EditDateAndTimeView(viewModel: viewModel))

        #expect(host.view != nil)
        #expect(viewModel.entry.isEmpty)
        #expect(viewModel.entry.preview == nil)
    }

    @Test("The sheet renders prefilled from a record's displayTime, with its preview line")
    func rendersPrefilled() throws {
        let viewModel = try viewModel(for: [child(#""recordId": "301", "archiveId": "5", "displayTime": "1985-10-23T17:00:00""#)])

        let host = render(EditDateAndTimeView(viewModel: viewModel))

        #expect(host.view != nil)
        #expect([viewModel.entry.year, viewModel.entry.month, viewModel.entry.day] == ["1985", "10", "23"])
        #expect([viewModel.entry.hour, viewModel.entry.minute, viewModel.entry.second] == ["05", "00", "00"])
        #expect(viewModel.entry.format == .pm)
        #expect(viewModel.entry.preview == "October 23, 1985 • 5PM")
    }

    @Test("The date sheet and the wheel card render on their own")
    func rendersPickers() throws {
        let entry = DateTimeEntry(displayTime: "1985-10-23T17:00:00", legacy: nil)
        let range = try #require(Calendar.current.date(from: DateComponents(year: 1900)))...Date()

        let dateSheet = render(PickADateSheet(selection: entry.pickerDate(), range: range) { _ in })
        let wheels = render(TimeWheelCard(entry: .constant(entry)))

        #expect(dateSheet.view != nil)
        #expect(wheels.view != nil)
    }

    @Test("UIKit gets the sheet with the design's corner radius and no bar look")
    func hostHasSheetCorners() throws {
        let file = try child(#""recordId": "301", "archiveId": "5""#)
        let barBefore = UINavigationBar.appearance().standardAppearance.backgroundColor

        let host = EditDateAndTimeView.host(for: file) { _ in }

        #expect(host.sheetPresentationController?.preferredCornerRadius == EditDateAndTimeView.sheetCornerRadius)
        #expect(UINavigationBar.appearance().standardAppearance.backgroundColor == barBefore, "the sheet leaves the bar look as it found it")
    }

    // MARK: - Common date

    @Test("Files that share a date open on it; files that differ open empty; an undated file is left out")
    func commonDate() throws {
        let dated = try child(#""recordId": "301", "archiveId": "5", "displayTime": "1985-10""#)
        let same = try child(#""recordId": "302", "archiveId": "5", "displayTime": "1985-10""#)
        let other = try child(#""recordId": "303", "archiveId": "5", "displayTime": "2001-02-03""#)
        let undated = try child(#""recordId": "304", "archiveId": "5""#)

        #expect(EditDateAndTimeViewModel.commonEntry(for: [dated, same]).edtfString == "1985-10")
        #expect(EditDateAndTimeViewModel.commonEntry(for: [dated, other]).isEmpty)
        #expect(EditDateAndTimeViewModel.commonEntry(for: [dated, undated]).edtfString == "1985-10")
        #expect(EditDateAndTimeViewModel.commonEntry(for: [undated]).isEmpty)
        #expect(EditDateAndTimeViewModel.commonEntry(for: []).isEmpty)
    }

    // MARK: - VoiceOver

    @Test("Every field has a name and a placeholder, and the pill reads its format with a hint")
    func accessibilityStrings() {
        let fields = DateTimeEntry.Field.allCases

        #expect(fields.map(\.label) == ["Year", "Month", "Day", "Hour", "Minute", "Second"])
        #expect(fields.map(\.placeholder) == ["YYYY", "MM", "DD", "hh", "mm", "ss"])
        #expect(fields.map(\.limit) == [4, 2, 2, 2, 2, 2])
        #expect(fields.map(\.next) == [.month, .day, nil, .minute, .second, nil])
        #expect("TimeFormatLabel".localized() == "Time format")
        #expect("TimeFormatHint".localized() == "Double tap to change")
        #expect("ClearDateAndTime".localized() == "Clear date and time")
        #expect("SaveNeedsDate".localized() == "Enter a date first")
        #expect("TimeNeedsFullDate".localized() == "A complete date is required when time is provided.")
        #expect("PickADate".localized() == "Pick a date")
        #expect("PickATime".localized() == "Pick a time")
    }

    // MARK: - Typing

    @Test("A field selects all its digits as it takes the focus, so the next digit replaces them")
    func focusSelectsAll() {
        let typed = typedField(.year, text: "1985")
        let window = shown(typed.textField)
        defer { window.isHidden = true }

        #expect(typed.textField.becomeFirstResponder())
        typed.coordinator.selectAll(in: typed.textField)

        #expect(typed.values.focus == .year)
        #expect(typed.textField.selectedTextRange.flatMap { typed.textField.text(in: $0) } == "1985")
        #expect(typed.coordinator.textField(typed.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 4), replacementString: "2"))
    }

    @Test("A letter and a digit past the field's width are refused; a backspace and a replacement go through")
    func refusesWhatDoesNotFit() {
        let typed = typedField(.month, text: "10")
        let field = typed.textField

        #expect(!typed.coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 2, length: 0), replacementString: "2"))
        #expect(!typed.coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 0, length: 2), replacementString: "a"))
        #expect(typed.coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 1, length: 1), replacementString: ""))
        #expect(typed.coordinator.textField(field, shouldChangeCharactersIn: NSRange(location: 0, length: 2), replacementString: "7"))
    }

    @Test("The fourth digit fills the year and passes the focus to the month; a full day keeps it")
    func fullFieldPassesFocus() {
        let year = typedField(.year, text: "198", focus: .year)
        year.textField.text = "1985"
        year.coordinator.textChanged(year.textField)

        #expect(year.values.entry.year == "1985")
        #expect(year.values.focus == .month)

        let day = typedField(.day, text: "2", focus: .day)
        day.textField.text = "23"
        day.coordinator.textChanged(day.textField)

        #expect(day.values.entry.day == "23")
        #expect(day.values.focus == .day)
    }

    @Test("A field that fills without the focus writes its digits and moves nothing")
    func fillWithoutFocusStays() {
        let month = typedField(.month, text: "1")
        month.textField.text = "10"
        month.coordinator.textChanged(month.textField)

        #expect(month.values.entry.month == "10")
        #expect(month.values.focus == nil)
    }

    @Test("A full month past 12 reads 12 before the focus moves on")
    func fullFieldIsPulledInsideItsBounds() {
        let month = typedField(.month, text: "2", focus: .month)
        month.textField.text = "22"
        month.coordinator.textChanged(month.textField)

        #expect(month.values.entry.month == "12")
        #expect(month.textField.text == "12")
        #expect(month.values.focus == .day)
    }

    @Test("A zero left in the day reads 01 when the focus leaves it")
    func leavingAFieldPullsItInsideItsBounds() {
        let day = typedField(.day, text: "0", focus: .day)

        day.coordinator.textFieldDidEndEditing(day.textField)

        #expect(day.values.entry.day == "01")
        #expect(day.textField.text == "01")
        #expect(day.values.focus == nil)
    }

    @Test("Starting and ending an edit reach the sheet's focus")
    func editingReportsFocus() {
        let typed = typedField(.hour, text: "")

        typed.coordinator.textFieldDidBeginEditing(typed.textField)
        #expect(typed.values.focus == .hour)

        typed.coordinator.textFieldDidEndEditing(typed.textField)
        #expect(typed.values.focus == nil)
    }

    @Test("A field is a centred number pad with its name and placeholder for VoiceOver")
    func fieldIsANumberPad() {
        let field = DateTimeDigitsField.textField(for: .year)

        #expect(field.keyboardType == .numberPad)
        #expect(field.accessibilityLabel == "Year")
        #expect(field.attributedPlaceholder?.string == "YYYY")
        #expect(field.textAlignment == .center)
        #expect(field.adjustsFontForContentSizeCategory)
    }

    // MARK: - Helpers

    private func child(_ fields: String) throws -> FileModel {
        let json = #"{ "items": [ { "type": "type.record.image", "folderLinkId": "900", \#(fields) } ] }"#
        let response = try FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: Data(json.utf8))
        let item = try #require(response.items?.first)
        return FileModel(model: item, permissions: [.read, .edit], accessRole: .editor)
    }

    private func viewModel(for files: [FileModel]) -> EditDateAndTimeViewModel {
        let viewModel = EditDateAndTimeViewModel(selectedFiles: files, hasUpdates: .constant(false))
        viewModel.sessionArchiveId = { 5 }
        return viewModel
    }

    /// Puts the view in a window the size of a phone and lays it out once.
    private func render<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        return host
    }

    /// The two values a digits field writes, held where a test can read them back.
    private final class FieldValues {
        var entry = DateTimeEntry()
        var focus: DateTimeEntry.Field?

        init(focus: DateTimeEntry.Field?) {
            self.focus = focus
        }
    }

    /// A digits field made outside a view: its values, its UIKit field and the coordinator that joins them.
    private func typedField(_ field: DateTimeEntry.Field, text: String, focus: DateTimeEntry.Field? = nil)
        -> (values: FieldValues, textField: UITextField, coordinator: DateTimeDigitsField.Coordinator) {
        let values = FieldValues(focus: focus)
        values.entry[field] = text
        let view = DateTimeDigitsField(
            field: field,
            entry: Binding(get: { values.entry }, set: { values.entry = $0 }),
            focus: Binding(get: { values.focus }, set: { values.focus = $0 })
        )
        let coordinator = view.makeCoordinator()
        let textField = DateTimeDigitsField.textField(for: field)
        textField.text = text
        textField.delegate = coordinator
        return (values, textField, coordinator)
    }

    /// Puts the field in a key window, as the sheet does, so it can take the first responder.
    private func shown(_ textField: UITextField) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let host = UIViewController()
        textField.frame = CGRect(x: 16, y: 100, width: 100, height: 24)
        host.view.addSubview(textField)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return window
    }
}
