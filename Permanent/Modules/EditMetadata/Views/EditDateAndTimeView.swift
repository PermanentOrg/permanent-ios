//
//  EditDateAndTimeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.08.2023.
//

import SwiftUI

/// The "Adjust date and time" sheet: a header with the preview line, the typed date and time boxes with their
/// native pickers, the zone row, the Clear row and the full view's switches, and Cancel and Save pinned under them.
struct EditDateAndTimeView: View {
    @StateObject var viewModel: EditDateAndTimeViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Set when UIKit presents the screen; it is told whether the date was saved.
    var onClose: ((Bool) -> Void)?

    typealias Side = DateTimeRangeEntry.Side

    @State private var focus: DateTimeEntry.Field?
    /// The To side's focused field; each side keeps its own, since both have a year, a month and so on.
    @State private var endFocus: DateTimeEntry.Field?
    @State private var calendarSide: Side?
    @State private var wheelsSide: Side?
    @State private var zoneSide: Side?
    @ScaledMetric(relativeTo: .subheadline) private var iconSize = 24.0

    static let sheetCornerRadius: CGFloat = 38

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        sideFields(.start)
                        if viewModel.range.isRange {
                            RangeSideLabel(title: "RangeTo".localized())
                            sideFields(.end)
                        }
                        if showsOptions {
                            optionsSection
                                .transition(reduceMotion ? .identity : .opacity)
                        }
                        ClearDateAndTimeRow { clear() }
                        if viewModel.offersMoreOptions {
                            MoreOptionsRow(isOpen: viewModel.showsOptions) { toggleOptions() }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                .onTapGesture { leaveFields() }
            }
            .safeAreaInset(edge: .bottom) { bottomButtons }
            .background(Color.white.ignoresSafeArea())
            .accessibilityHidden(zoneSide != nil)
            if let zoneSide {
                TimeZonePickerSheet(entry: entry(zoneSide)) { closeZonePicker() }
                    .transition(reduceMotion ? .identity : .move(edge: .trailing))
                    .zIndex(1)
            }
            if viewModel.showConfirmation {
                CustomDialogView(isActive: $viewModel.showConfirmation, title: "ChangeDateAndTime".localized(), message: confirmationMessage, buttonTitle: "Modify") {
                    viewModel.applyChanges()
                }
                .frame(width: 294)
            }
        }
        .sheet(item: $calendarSide) { side in
            PickADateSheet(selection: calendarStart(side), range: viewModel.startingDate...viewModel.endingDate) { picked in
                entry(side).wrappedValue.set(date: picked)
            }
        }
        .onAppear { viewModel.readZoneIfNeeded() }
        .onChange(of: focus) { field in
            if field != nil { closeWheels() }
        }
        .onChange(of: endFocus) { field in
            if field != nil { closeWheels() }
        }
        .onChange(of: viewModel.validation) { reason in
            if let reason { UIAccessibility.post(notification: .announcement, argument: reason) }
        }
        .onChange(of: viewModel.isLoading) { loading in
            if loading { UIAccessibility.post(notification: .announcement, argument: "Saving".localized()) }
        }
        .onChange(of: viewModel.changesWereSaved) { saved in
            if saved {
                viewModel.changesWereSaved = false
                close(saved: true)
            }
        }
        .onChange(of: viewModel.changesConfirmed) { confirmed in
            if confirmed { viewModel.applyChanges() }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Error".localized()), message: Text("ErrorMessage".localized()), dismissButton: .default(Text(String.ok)) {
                viewModel.showAlert = false
            })
        }
    }

    // MARK: - Parts

    private var header: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: 48, height: 1)
            VStack(spacing: 4) {
                Text("AdjustDateAndTime".localized())
                    .font(.custom("Usual-Medium", size: 16, relativeTo: .body))
                    .foregroundColor(.darkBlue)
                    .accessibilityAddTraits(.isHeader)
                if let preview = viewModel.range.preview {
                    Text(preview)
                        .font(.custom("Usual-Regular", size: 12, relativeTo: .caption))
                        .foregroundColor(.blue400)
                }
                if let reason = viewModel.validation {
                    Text(reason)
                        .font(.custom("Usual-Regular", size: 12, relativeTo: .caption))
                        .foregroundColor(.error500)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            SheetCircleButton(symbol: "xmark", label: "Close".localized(), look: .light) { close(saved: false) }
        }
        .padding(14)
    }

    /// One side's date box, time box and zone row. Unknown greys all three; a symbol greys the clock and the
    /// zone, which then read empty.
    @ViewBuilder
    private func sideFields(_ side: Side) -> some View {
        let value = entry(side).wrappedValue
        let isUnknown = value.qualifiers.contains(.unknown)
        let hidesClock = isUnknown || value.qualifiers.symbol != nil
        dateBox(side)
            .greyedOut(isUnknown)
        timeBox(side)
            .greyedOut(hidesClock)
            .padding(.top, 8)
            .zIndex(1)
        TimeZoneRow(
            zone: value.zone, wallClock: value.offsetClock(), isEnabled: value.hasTime && !hidesClock,
            showsNeedsTimeHint: !hidesClock
        ) { openZonePicker(side) }
    }

    private func dateBox(_ side: Side) -> some View {
        DateTimeFieldsBox(fields: [.year, .month, .day], separator: "/", entry: entry(side), focus: focus(side)) {
            TimeFormatPill(format: entry(side).wrappedValue.format) {}
                .hidden()
                .accessibilityHidden(true)
            accessoryButton("calendar", label: "PickADate".localized()) {
                leaveFields()
                calendarSide = side
            }
        }
    }

    private func timeBox(_ side: Side) -> some View {
        DateTimeFieldsBox(fields: [.hour, .minute, .second], separator: ":", entry: entry(side), focus: focus(side)) {
            TimeFormatPill(format: entry(side).wrappedValue.format) {
                entry(side).wrappedValue.format = entry(side).wrappedValue.format.next
            }
            accessoryButton("clock", label: "PickATime".localized()) { toggleWheels(side) }
        }
        .overlay(alignment: .topTrailing) {
            if wheelsSide == side {
                TimeWheelCard(entry: entry(side))
                    .padding(.trailing, DateTimeDigitsField.boxPadding)
                    .offset(y: -16)
                    .transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.96, anchor: .topTrailing)))
            }
        }
    }

    /// The full view, in the design's order: the range switch, a rule, each side's three switches, a rule. In a
    /// range each side's switches sit under its own caps label.
    @ViewBuilder private var optionsSection: some View {
        OptionToggleRow(title: "UseADateRange".localized(), isOn: viewModel.range.isRange) { setRange($0) }
            .padding(.vertical, -8)
        rule
        ForEach(viewModel.range.isRange ? Side.allCases : [.start]) { side in
            if viewModel.range.isRange {
                RangeSideLabel(title: (side == .start ? "RangeFrom" : "RangeTo").localized())
            }
            qualifierRows(side)
                .padding(.vertical, -8)
        }
        rule
    }

    private func qualifierRows(_ side: Side) -> some View {
        let qualifiers = entry(side).wrappedValue.qualifiers
        let rows: [(DateQualifiers, String)] = [(.approximate, "DateApproximate"), (.uncertain, "DateUncertain"), (.unknown, "DateUnknown")]
        return VStack(spacing: 0) {
            ForEach(rows, id: \.1) { qualifier, title in
                OptionToggleRow(
                    title: title.localized(), isOn: qualifiers.contains(qualifier),
                    isEnabled: qualifier == .unknown || !qualifiers.contains(.unknown)
                ) { isOn in
                    leaveFields()
                    viewModel.toggle(qualifier, on: isOn, side: side)
                }
            }
        }
    }

    private var rule: some View {
        Rectangle()
            .fill(Color.blue50)
            .frame(height: 1)
    }

    private func accessoryButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundColor(.darkBlue)
                .frame(width: iconSize, height: iconSize)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var bottomButtons: some View {
        HStack(spacing: 24) {
            Button {
                close(saved: false)
            } label: {
                Text("Cancel".localized())
            }
            .buttonStyle(CustomButtonStyle(backgroundColor: .blue25, foregroundColor: .darkBlue, height: 56, cornerRadius: 12))
            Button {
                save()
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .accessibilityLabel("Saving".localized())
                } else {
                    Text("Save".localized())
                }
            }
            .buttonStyle(CustomButtonStyle(backgroundColor: .darkBlue, foregroundColor: .white, height: 56, cornerRadius: 12))
            .disabled(viewModel.isLoading || viewModel.validation != nil)
            .opacity(viewModel.validation == nil ? 1 : 0.4)
        }
        .font(.custom("Usual-Medium", size: 14, relativeTo: .subheadline))
        .dynamicTypeSize(...DynamicTypeSize.large)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 32)
        .background(Color.white)
    }

    // MARK: - Actions

    private var confirmationMessage: String {
        let count = viewModel.selectedFiles.count
        return count > 1 ? String(format: "ChangeDateAndTimeOther".localized(), count) : "ChangeDateAndTimeOne".localized()
    }

    /// The full view shows only for a record that can save it, and only while open.
    private var showsOptions: Bool {
        viewModel.offersMoreOptions && viewModel.showsOptions
    }

    private func entry(_ side: Side) -> Binding<DateTimeEntry> {
        side == .start ? $viewModel.entry : $viewModel.endEntry
    }

    private func focus(_ side: Side) -> Binding<DateTimeEntry.Field?> {
        side == .start ? $focus : $endFocus
    }

    /// The calendar opens on the side's typed date, kept inside its range.
    private func calendarStart(_ side: Side) -> Date {
        min(max(entry(side).wrappedValue.pickerDate(), viewModel.startingDate), viewModel.endingDate)
    }

    /// One file saves at once; two or more ask first.
    private func save() {
        leaveFields()
        if viewModel.selectedFiles.count > 1 {
            viewModel.showConfirmation = true
        } else {
            viewModel.applyChanges()
        }
    }

    private func clear() {
        leaveFields()
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
            viewModel.clear()
        }
    }

    /// The full view opens and closes in place; Reduce Motion swaps it. VoiceOver is told the screen changed.
    private func toggleOptions() {
        leaveFields()
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
            viewModel.showsOptions.toggle()
        }
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }

    private func setRange(_ isOn: Bool) {
        leaveFields()
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
            viewModel.setRange(on: isOn)
        }
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }

    private func toggleWheels(_ side: Side) {
        focus = nil
        endFocus = nil
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            wheelsSide = wheelsSide == side ? nil : side
        }
    }

    private func closeWheels() {
        guard wheelsSide != nil else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            wheelsSide = nil
        }
    }

    /// The Time zone screen slides in from the right over the sheet's content; Reduce Motion swaps the two.
    private func openZonePicker(_ side: Side) {
        leaveFields()
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
            zoneSide = side
        }
    }

    private func closeZonePicker() {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
            zoneSide = nil
        }
    }

    /// Puts the keyboard and the wheel card away.
    private func leaveFields() {
        focus = nil
        endFocus = nil
        closeWheels()
    }

    private func close(saved: Bool) {
        if let onClose {
            onClose(saved)
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

private extension View {
    /// A box a toggle switched off: pale, out of reach of taps and of VoiceOver.
    func greyedOut(_ isGreyed: Bool) -> some View {
        opacity(isGreyed ? 0.4 : 1)
            .allowsHitTesting(!isGreyed)
            .accessibilityHidden(isGreyed)
    }
}

extension EditDateAndTimeView {
    /// The screen for one file, for UIKit to present. It closes itself, then tells `onClose` whether the date was saved.
    /// A door that has read the record passes it; a list door passes none and the sheet reads it.
    static func host(for file: FileModel, record: RecordVOData? = nil, onClose: @escaping (Bool) -> Void) -> UIViewController {
        weak var host: UIViewController?
        let viewModel = EditDateAndTimeViewModel(file: file, record: record, hasUpdates: .constant(false))
        let view = EditDateAndTimeView(viewModel: viewModel, onClose: { saved in
            host?.dismiss(animated: true) { onClose(saved) }
        })
        let controller = UIHostingController(rootView: view)
        controller.modalPresentationStyle = .pageSheet
        controller.sheetPresentationController?.preferredCornerRadius = sheetCornerRadius
        host = controller
        return controller
    }
}

struct EditDateAndTimeView_Previews: PreviewProvider {
    @State static var hasUpdates: Bool = false
    static var previews: some View {
        EditDateAndTimeView(viewModel: EditDateAndTimeViewModel(selectedFiles: [], hasUpdates: $hasUpdates))
    }
}
