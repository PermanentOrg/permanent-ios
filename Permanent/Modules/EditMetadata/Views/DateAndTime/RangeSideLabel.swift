//
//  RangeSideLabel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.11.2026.
//

import SwiftUI

/// The line that heads one side of a range: "FROM" or "TO" in small caps at the leading edge, and the side's red
/// Clear at the trailing one when given. The Clear takes 44pt of touch on a 24pt line.
struct RangeSideLabel: View {
    let title: String
    var onClear: (() -> Void)?
    @ScaledMetric(relativeTo: .subheadline) private var iconSize = 24.0

    var body: some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.custom("Usual-Regular", size: 10, relativeTo: .caption2))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundColor(.darkBlue)
                .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            if let onClear {
                Button(role: .destructive, action: onClear) {
                    HStack(spacing: 8) {
                        Image("broomWide")
                            .resizable()
                            .frame(width: iconSize, height: iconSize)
                        Text("RangeClearSide".localized())
                            .font(DateTimeDigitsField.font)
                    }
                    .foregroundColor(.error500)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, -10)
                .accessibilityLabel(String(format: "ClearRangeSide".localized(), title))
            }
        }
    }
}
