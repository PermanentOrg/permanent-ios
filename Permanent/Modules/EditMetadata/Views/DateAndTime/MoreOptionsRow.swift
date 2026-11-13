//
//  MoreOptionsRow.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.11.2026.
//

import SwiftUI

/// The row under "Clear date and time" that opens the full view and closes it again. As on the Clear row, only
/// the icon and the words take the tap.
struct MoreOptionsRow: View {
    let isOpen: Bool
    let action: () -> Void
    @ScaledMetric(relativeTo: .subheadline) private var iconSize = 24.0

    static func title(isOpen: Bool) -> String {
        (isOpen ? "FewerOptions" : "MoreOptions").localized()
    }

    var body: some View {
        HStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                        .frame(width: iconSize, height: iconSize)
                    Text(Self.title(isOpen: isOpen))
                        .font(.custom("Usual-Medium", size: 14, relativeTo: .subheadline))
                }
                .foregroundColor(.darkBlue)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.vertical, -4)
    }
}
