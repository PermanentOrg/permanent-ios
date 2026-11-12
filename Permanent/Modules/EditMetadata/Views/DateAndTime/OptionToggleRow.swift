//
//  OptionToggleRow.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.11.2026.
//

import SwiftUI

/// One switch row of the full view: its name at the leading edge and a 36 by 20 switch at the trailing one, on a
/// 24pt line. The whole row is one button, so VoiceOver reads the name, the state and the action as one switch.
struct OptionToggleRow: View {
    let title: String
    let isOn: Bool
    var isEnabled = true
    /// Called with the state the tap asks for.
    let action: (Bool) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let switchSize = CGSize(width: 36, height: 20)
    static let knobInset: CGFloat = 2
    static let lineHeight: CGFloat = 24
    /// The knob's shadow colour, drawn twice: a tight one and a wider one.
    static let knobShadow = Color(red: 16 / 255, green: 24 / 255, blue: 40 / 255)

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
            .frame(minHeight: Self.lineHeight)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(title)
        .accessibilityValue(Self.spokenValue(isOn: isOn))
        .accessibilityAddTraits(Self.traits)
    }

    /// The track and its knob at the design's fixed size, green when on, paler when the row is greyed. The
    /// knob's shadows stay inside the track.
    private var switchDrawing: some View {
        Capsule()
            .fill(isOn ? Color.success500 : Color.blue50)
            .frame(width: Self.switchSize.width, height: Self.switchSize.height)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(Color.white)
                    .shadow(color: Self.knobShadow.opacity(0.06), radius: 1, y: 1)
                    .shadow(color: Self.knobShadow.opacity(0.1), radius: 1.5, y: 1)
                    .padding(Self.knobInset)
            }
            .clipShape(Capsule())
            .opacity(isEnabled ? 1 : 0.5)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isOn)
    }
}
