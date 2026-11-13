//
//  ClearDateAndTimeRow.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import SwiftUI

/// The red "Clear date and time" row under the time box: a broom and the text at the leading edge, and only they
/// take the tap, so a touch on the empty right of the row does nothing.
struct ClearDateAndTimeRow: View {
    let action: () -> Void
    @ScaledMetric(relativeTo: .subheadline) private var iconSize = 24.0

    var body: some View {
        HStack(spacing: 0) {
            Button(role: .destructive, action: action) {
                HStack(spacing: 8) {
                    Image("broomWide")
                        .resizable()
                        .frame(width: iconSize, height: iconSize)
                    Text("ClearDateAndTime".localized())
                        .font(DateTimeDigitsField.font)
                }
                .foregroundColor(.error500)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.vertical, -4)
    }
}
