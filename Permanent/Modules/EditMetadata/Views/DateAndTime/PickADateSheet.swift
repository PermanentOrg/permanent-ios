//
//  PickADateSheet.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import SwiftUI

/// The second sheet behind the calendar icon: the native calendar between an X and a check. The check hands the
/// picked day back; the X drops it.
struct PickADateSheet: View {
    @State var selection: Date
    let range: ClosedRange<Date>
    let onPick: (Date) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                SheetCircleButton(symbol: "xmark", label: "Close".localized(), look: .light) { dismiss() }
                Text("PickADate".localized())
                    .font(.custom("Usual-Medium", size: 16, relativeTo: .body))
                    .foregroundColor(.darkBlue)
                    .frame(maxWidth: .infinity)
                    .accessibilityAddTraits(.isHeader)
                SheetCircleButton(symbol: "checkmark", label: "Save".localized(), look: .dark) {
                    onPick(selection)
                    dismiss()
                }
            }
            .padding(14)
            ScrollView {
                DatePicker("PickADate".localized(), selection: $selection, in: range, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(.darkBlue)
                    .padding(.horizontal, 16)
            }
        }
        .background(Color.white)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}
