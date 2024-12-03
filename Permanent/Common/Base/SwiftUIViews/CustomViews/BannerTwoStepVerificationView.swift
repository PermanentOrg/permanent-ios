//
//  BannerTwoStepVerificationView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.11.2024.

import SwiftUI

/// A banner view that displays the current status of two-step verification
/// Shows different colors and icons based on whether 2FA is enabled or disabled
struct BannerTwoStepVerificationView: View {
    /// Boolean indicating if two-step verification is currently enabled
    let isEnabled: Bool
    
    /// The status message to display in the banner
    /// Returns "enabled" or "disabled" based on isEnabled state
    private var message: String {
        isEnabled ? "enabled." : "disabled."
    }
    
    /// The background color of the banner
    /// Returns green for enabled state, red for disabled state
    private var backgroundColor: Color {
        isEnabled ? Color(red: 0.82, green: 0.98, blue: 0.88) : Color(red: 1, green: 0.89, blue: 0.89)
    }
    
    /// The text color used in the banner
    /// Returns dark green for enabled state, dark red for disabled state
    private var textColor: Color {
        isEnabled ? Color(red: 0.01, green: 0.48, blue: 0.28) : Color(red: 0.7, green: 0.14, blue: 0.1)
    }
    
    /// The icon to display in the banner
    /// Returns checkmark icon for enabled state, warning icon for disabled state
    private var image: Image {
        isEnabled ? Image(.twoStepEnabledIcon) : Image(.twoStepDisabledIcon)
    }
    
    var body: some View {
        ZStack() {
            backgroundColor
            HStack(spacing: 0) {
                image
                    .frame(width: 48, height: 48)
                    .layoutPriority(1)
                HStack(spacing: 0) {
                    Text("Two-step verification is ") +
                    Text(message)
                        .bold()
                }
                .font(
                    .custom(
                        FontName.usualRegular.rawValue,
                        fixedSize: 14)
                )
                .foregroundColor(textColor)
                .lineLimit(1)
                .layoutPriority(1)
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 72)
    }
}
