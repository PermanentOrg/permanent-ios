//
//  DateTimeFieldsBox.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import SwiftUI

/// The bordered box of the date or time fields: equal centred fields with a separator between them, then the box's
/// own controls on the right. The focused field sits on a pale rounded ground, and the box's border darkens and lifts.
struct DateTimeFieldsBox<Accessory: View>: View {
    let fields: [DateTimeEntry.Field]
    let separator: String
    @Binding var entry: DateTimeEntry
    @Binding var focus: DateTimeEntry.Field?
    @ViewBuilder let accessory: () -> Accessory

    private var isFocused: Bool {
        fields.contains { $0 == focus }
    }

    var body: some View {
        HStack(spacing: DateTimeDigitsField.boxPadding) {
            HStack(spacing: 8) {
                ForEach(fields, id: \.self) { field in
                    DateTimeDigitsField(field: field, entry: $entry, focus: $focus)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(focus == field ? Color.blue25 : Color.clear))
                    if field != fields.last {
                        Text(separator)
                            .font(DateTimeDigitsField.font)
                            .foregroundColor(.blue100)
                    }
                }
            }
            accessory()
        }
        .padding(DateTimeDigitsField.boxPadding)
        .background(
            RoundedRectangle(cornerRadius: DateTimeDigitsField.boxCornerRadius)
                .fill(Color.white)
                .shadow(color: Color.darkBlue.opacity(isFocused ? 0.12 : 0), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DateTimeDigitsField.boxCornerRadius)
                .stroke(isFocused ? Color.blue100 : Color.blue50, lineWidth: 1)
        )
    }
}
