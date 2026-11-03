//
//  TimeZoneOptionRow.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.10.2026.
//

import SwiftUI

/// One zone in the Time zone list: the offset in grey, then "Country, " and the city in medium, in the sheet row's
/// two-column label. The chosen row sits on a pale ground with a green check.
struct TimeZoneOptionRow: View {
    let option: TimeZoneOption
    let wallClock: DateComponents
    let isChosen: Bool
    let action: () -> Void
    @ScaledMetric(relativeTo: .subheadline) private var checkSize = 24.0

    static let cornerRadius: CGFloat = 8

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                TimeZoneRow.OffsetAndPlace(offset: Text(option.offsetLabel(at: wallClock)).foregroundColor(.blue400), place: place)
                    .font(DateTimeDigitsField.font)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if isChosen {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.success500)
                        .frame(width: checkSize, height: checkSize)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: Self.cornerRadius).fill(isChosen ? Color.blue25 : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.spokenName(at: wallClock))
        .accessibilityAddTraits(isChosen ? [.isSelected] : [])
    }

    private var place: Text {
        let city = Text(option.city).font(.custom("Usual-Medium", size: 14, relativeTo: .subheadline)).foregroundColor(.darkBlue)
        guard let country = option.countryName else { return city }
        return Text(country + ", ").foregroundColor(.darkBlue) + city
    }
}
