//
//  ClearDateAndTimeRow.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import SwiftUI

/// The red "Clear date and time" row under the time box: a broom and the text, the whole row a button.
struct ClearDateAndTimeRow: View {
    let action: () -> Void
    @ScaledMetric(relativeTo: .subheadline) private var iconSize = 24.0

    var body: some View {
        Button(role: .destructive, action: action) {
            HStack(spacing: 12) {
                Image(systemName: "eraser.line.dashed")
                    .font(.title3)
                    .frame(width: iconSize, height: iconSize)
                Text("ClearDateAndTime".localized())
                    .font(DateTimeDigitsField.font)
                Spacer(minLength: 0)
            }
            .foregroundColor(.error500)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
