//
//  ClearDateAndTimeRow.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import SwiftUI

/// The red "Clear date and time" row; only the icon and text take the tap. Off the sheet for now: while screens
/// fall back to the old date field, a cleared record shows its old date again.
struct ClearDateAndTimeRow: View {
    let action: () -> Void
    @ScaledMetric(relativeTo: .subheadline) private var iconSize = 24.0

    var body: some View {
        HStack(spacing: 0) {
            Button(role: .destructive, action: action) {
                HStack(spacing: 12) {
                    Image(systemName: "eraser.line.dashed")
                        .font(.title3)
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
    }
}
