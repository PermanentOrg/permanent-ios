//
//  TimeZoneSearchField.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.10.2026.
//

import SwiftUI

/// The search box over the zone list: a magnifier on a pale square, the typed text, and a circle that clears it.
/// The border darkens and the box lifts while the field has the keyboard.
struct TimeZoneSearchField: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @ScaledMetric(relativeTo: .subheadline) private var squareSize = 32.0
    @ScaledMetric(relativeTo: .subheadline) private var clearSize = 24.0

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.darkBlue)
                .frame(width: squareSize, height: squareSize)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.blue25))
                .accessibilityHidden(true)
            TextField("", text: $text)
                .font(DateTimeDigitsField.font)
                .foregroundColor(.darkBlue)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .overlay(alignment: .leading) {
                    if text.isEmpty {
                        Text("SearchTimeZones".localized())
                            .font(DateTimeDigitsField.font)
                            .foregroundColor(.blue200)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityLabel("SearchTimeZones".localized())
                .accessibilityAddTraits(.isSearchField)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue200)
                        .frame(width: clearSize, height: clearSize)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("ClearSearch".localized())
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 16)
        .padding(.vertical, 8)
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
