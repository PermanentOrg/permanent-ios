//
//  EditDateAndTimeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.08.2023.
//

import SwiftUI

/// The "Adjust date and time" sheet: a header with the preview line, the typed date and time boxes with their
/// native pickers, the Clear row, and Cancel and Save pinned under them.
struct EditDateAndTimeView: View {
    @StateObject var viewModel: EditDateAndTimeViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Set when UIKit presents the screen; it is told whether the date was saved.
    var onClose: ((Bool) -> Void)?

    @State private var focus: DateTimeEntry.Field?
    @State private var showsDateSheet = false
    @State private var showsWheels = false
    @ScaledMetric(relativeTo: .subheadline) private var iconSize = 24.0

    static let sheetCornerRadius: CGFloat = 38

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        dateBox
                        timeBox
                            .padding(.top, 8)
                            .zIndex(1)
                        ClearDateAndTimeRow { clear() }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                .onTapGesture { leaveFields() }
            }
            .safeAreaInset(edge: .bottom) { bottomButtons }
            .background(Color.white.ignoresSafeArea())
            if viewModel.showConfirmation {
                CustomDialogView(isActive: $viewModel.showConfirmation, title: "ChangeDateAndTime".localized(), message: confirmationMessage, buttonTitle: "Modify") {
                    viewModel.applyChanges()
                }
                .frame(width: 294)
            }
        }
        .sheet(isPresented: $showsDateSheet) {
            PickADateSheet(selection: calendarStart, range: viewModel.startingDate...viewModel.endingDate) { picked in
                viewModel.entry.set(date: picked)
            }
        }
        .onChange(of: focus) { field in
            if field != nil { closeWheels() }
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
                if let preview = viewModel.entry.preview {
                    Text(preview)
                        .font(.custom("Usual-Regular", size: 12, relativeTo: .caption))
                        .foregroundColor(.blue400)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            SheetCircleButton(symbol: "xmark", label: "Close".localized(), look: .light) { close(saved: false) }
        }
        .padding(14)
    }

    private var dateBox: some View {
        DateTimeFieldsBox(fields: [.year, .month, .day], separator: "/", entry: $viewModel.entry, focus: $focus) {
            TimeFormatPill(format: viewModel.entry.format) {}
                .hidden()
                .accessibilityHidden(true)
            accessoryButton("calendar", label: "PickADate".localized()) {
                leaveFields()
                showsDateSheet = true
            }
        }
    }

    private var timeBox: some View {
        DateTimeFieldsBox(fields: [.hour, .minute, .second], separator: ":", entry: $viewModel.entry, focus: $focus) {
            TimeFormatPill(format: viewModel.entry.format) {
                viewModel.entry.format = viewModel.entry.format.next
            }
            accessoryButton("clock", label: "PickATime".localized()) { toggleWheels() }
        }
        .overlay(alignment: .topTrailing) {
            if showsWheels {
                TimeWheelCard(entry: $viewModel.entry)
                    .padding(.trailing, DateTimeDigitsField.boxPadding)
                    .offset(y: -16)
                    .transition(reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.96, anchor: .topTrailing)))
            }
        }
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
            .disabled(viewModel.isLoading)
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

    /// The calendar opens on the typed date, kept inside its range.
    private var calendarStart: Date {
        min(max(viewModel.entry.pickerDate(), viewModel.startingDate), viewModel.endingDate)
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
        viewModel.entry.clear()
    }

    private func toggleWheels() {
        focus = nil
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            showsWheels.toggle()
        }
    }

    private func closeWheels() {
        guard showsWheels else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            showsWheels = false
        }
    }

    /// Puts the keyboard and the wheel card away.
    private func leaveFields() {
        focus = nil
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

extension EditDateAndTimeView {
    /// The screen for one file, for UIKit to present. It closes itself, then tells `onClose` whether the date was saved.
    static func host(for file: FileModel, onClose: @escaping (Bool) -> Void) -> UIViewController {
        weak var host: UIViewController?
        let view = EditDateAndTimeView(viewModel: EditDateAndTimeViewModel(selectedFiles: [file], hasUpdates: .constant(false)), onClose: { saved in
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
