//
//  SheetCircleButton.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import SwiftUI

/// The round button in a sheet's header: a white circle with a shadow for the X, a dark-blue circle for the check.
struct SheetCircleButton: View {
    enum Look {
        case light, dark
    }

    let symbol: String
    let label: String
    let look: Look
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(look == .dark ? .white : .darkBlue)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(look == .dark ? Color.darkBlue : Color.white)
                        .shadow(color: Color.darkBlue.opacity(look == .dark ? 0 : 0.16), radius: 8, y: 2)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityShowsLargeContentViewer()
    }
}
