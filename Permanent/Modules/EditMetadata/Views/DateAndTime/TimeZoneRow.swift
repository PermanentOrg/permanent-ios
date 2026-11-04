//
//  TimeZoneRow.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.10.2026.
//

import SwiftUI

/// The zone row under the time box: a globe, the chosen zone as "GMT+02:00  Romania, Bucharest" or "Select time
/// zone" while unset, and a chevron; a thin rule closes it. The whole row is a button, greyed until a time is typed.
struct TimeZoneRow: View {
    let zone: TimeZoneOption?
    let wallClock: DateComponents
    var isEnabled = true
    let action: () -> Void
    @ScaledMetric(relativeTo: .subheadline) private var iconSize = 24.0

    /// The offset, then the place on the same line: a long country name shrinks a little, and the few longest lose
    /// their middle so the city stays. At accessibility sizes the two stack and the place wraps. The list rows use it too.
    struct OffsetAndPlace: View {
        let offset: Text
        let place: Text
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize

        var body: some View {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 2) {
                    offset
                    place
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    offset.fixedSize(horizontal: true, vertical: false)
                    place
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .truncationMode(.middle)
                }
            }
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.title3)
                        .foregroundColor(isEnabled ? .darkBlue : .blue200)
                        .frame(width: iconSize, height: iconSize)
                    if !isEnabled {
                        Text("TimeZoneNeedsTime".localized()).foregroundColor(.blue200)
                    } else if let zone {
                        OffsetAndPlace(offset: Text(zone.offsetLabel(at: wallClock)).foregroundColor(.darkBlue), place: Text(zone.placeName).foregroundColor(.blue400))
                    } else {
                        Text("SelectTimeZone".localized()).foregroundColor(.blue400)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.blue200)
                }
                .font(DateTimeDigitsField.font)
                .multilineTextAlignment(.leading)
                .padding(.vertical, 12)
                Rectangle()
                    .fill(Color.blue50)
                    .frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel("TimeZone".localized())
        .accessibilityValue(isEnabled ? zone?.spokenName(at: wallClock) ?? "TimeZoneNotSet".localized() : "TimeZoneNeedsTime".localized())
        .accessibilityHint(isEnabled ? "TimeZoneHint".localized() : "")
    }
}
