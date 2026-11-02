//
//  TimeFormatPill.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import SwiftUI

/// The small pill in the time box that reads AM, PM or 24H; a tap cycles it. The date box holds a hidden one so
/// its fields line up with the time fields.
struct TimeFormatPill: View {
    let format: DateTimeEntry.TimeFormat
    let action: () -> Void
    @ScaledMetric(relativeTo: .caption2) private var height = 24.0

    var body: some View {
        Button(action: action) {
            Text(format.label)
                .font(.custom("Usual-Regular", size: 10, relativeTo: .caption2))
                .tracking(1.6)
                .foregroundColor(.darkBlue)
                .padding(.horizontal, 8)
                .frame(minWidth: 36, minHeight: height)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue25))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("TimeFormatLabel".localized())
        .accessibilityValue(format.label)
        .accessibilityHint("TimeFormatHint".localized())
    }
}
