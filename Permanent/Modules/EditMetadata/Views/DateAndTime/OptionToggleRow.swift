//
//  OptionToggleRow.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.11.2026.
//

import SwiftUI

/// One switch row of the full view: its name at the leading edge and a 36 by 20 switch at the trailing one. The
/// whole row is one button, so VoiceOver reads the name, the state and the action as one switch.
struct OptionToggleRow: View {
    let title: String
    let isOn: Bool
    var isEnabled = true
    /// Called with the state the tap asks for.
    let action: (Bool) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let switchSize = CGSize(width: 36, height: 20)
    static let knobInset: CGFloat = 2

    /// The switch trait exists from iOS 17; before it the row reads as a button with its on or off value.
    static var traits: AccessibilityTraits {
        if #available(iOS 17.0, *) {
            return [.isButton, .isToggle]
        }
        return .isButton
    }

    static func spokenValue(isOn: Bool) -> String {
        (isOn ? "SwitchOn" : "SwitchOff").localized()
    }

    var body: some View {
        Button {
            action(!isOn)
        } label: {
            HStack(spacing: 16) {
                Text(title)
                    .font(DateTimeDigitsField.font)
                    .foregroundColor(isEnabled ? .darkBlue : .blue200)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                switchDrawing
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(title)
        .accessibilityValue(Self.spokenValue(isOn: isOn))
        .accessibilityAddTraits(Self.traits)
    }

    /// The track and its knob at the design's fixed size, green when on, paler when the row is greyed.
    private var switchDrawing: some View {
        Capsule()
            .fill(isOn ? Color.success500 : Color.blue50)
            .frame(width: Self.switchSize.width, height: Self.switchSize.height)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.darkBlue.opacity(0.16), radius: 2, y: 1)
                    .padding(Self.knobInset)
            }
            .opacity(isEnabled ? 1 : 0.5)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isOn)
    }
}
