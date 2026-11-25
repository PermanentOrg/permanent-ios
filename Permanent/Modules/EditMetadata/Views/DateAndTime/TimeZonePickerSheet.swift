//
//  TimeZonePickerSheet.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.10.2026.
//

import SwiftUI

/// The Time zone screen: a header with a back circle, the search field, the "No time zone" row, then every zone by
/// region with the chosen one marked. It slides in over the date sheet; a row tap chooses and slides back.
struct TimeZonePickerSheet: View {
    @Binding var entry: DateTimeEntry
    let onClose: () -> Void
    @State private var searchText = ""

    /// What the list shows: the "No time zone" row while the search is empty, a chosen zone the list does not
    /// carry (an alias, UTC) above the first region, then the regions that match.
    struct Listing: Equatable {
        let showsNoZoneRow: Bool
        let unlistedChosen: TimeZoneOption?
        let regions: [TimeZoneCatalog.Region]

        var isEmpty: Bool {
            !showsNoZoneRow && unlistedChosen == nil && regions.isEmpty
        }
    }

    var body: some View {
        let listing = Self.listing(for: entry, search: searchText)
        VStack(spacing: 0) {
            header
            TimeZoneSearchField(text: $searchText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            if listing.showsNoZoneRow {
                // Above the list, so a chosen zone deep in it is one tap from unset.
                noZoneRow
                    .padding(.horizontal, 16)
                Rectangle()
                    .fill(Color.blue50)
                    .frame(height: 1)
                    .padding(.horizontal, 16)
            }
            list(listing, at: entry.offsetClock())
        }
        .background(Color.white.ignoresSafeArea())
    }

    static func listing(for entry: DateTimeEntry, search: String, now: Date = Date()) -> Listing {
        let clock = entry.offsetClock(now: now)
        let needle = search.trimmingCharacters(in: .whitespaces)
        let unlisted = entry.zone.flatMap { TimeZoneCatalog.isListed($0.identifier) ? nil : $0 }
        let shownUnlisted = unlisted.flatMap { needle.isEmpty || $0.matches(needle, at: clock) ? $0 : nil }
        return Listing(showsNoZoneRow: needle.isEmpty, unlistedChosen: shownUnlisted, regions: TimeZoneCatalog.search(needle, at: clock))
    }

    /// Writes the zone, or none, and slides back.
    func choose(_ identifier: String?) {
        entry.timeZoneIdentifier = identifier
        onClose()
    }

    // MARK: - Parts

    private var header: some View {
        HStack(spacing: 0) {
            SheetCircleButton(symbol: "arrow.left", label: "Back".localized(), look: .light) { onClose() }
            Text("TimeZone".localized())
                .font(.custom("Usual-Medium", size: 16, relativeTo: .body))
                .foregroundColor(.darkBlue)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)
            Color.clear
                .frame(width: 48, height: 1)
        }
        .padding(14)
    }

    private func list(_ listing: Listing, at clock: DateComponents) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if let unlisted = listing.unlistedChosen {
                        row(unlisted, at: clock)
                    }
                    ForEach(listing.regions) { region in
                        regionHeader(region.name)
                        ForEach(region.options) { option in
                            row(option, at: clock)
                        }
                    }
                    if listing.isEmpty {
                        Text("NoMatchingTimeZones".localized())
                            .font(DateTimeDigitsField.font)
                            .foregroundColor(.blue400)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .scrollDismissesKeyboard(.immediately)
            .onAppear {
                guard let chosen = entry.timeZoneIdentifier else { return }
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) { proxy.scrollTo(chosen, anchor: .center) }
            }
        }
    }

    private var noZoneRow: some View {
        Button {
            choose(nil)
        } label: {
            HStack(spacing: 8) {
                Text("NoTimeZone".localized())
                    .font(DateTimeDigitsField.font)
                    .foregroundColor(.darkBlue)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: TimeZoneOptionRow.cornerRadius).fill(entry.timeZoneIdentifier == nil ? Color.blue25 : Color.clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(entry.timeZoneIdentifier == nil ? [.isSelected] : [])
    }

    private func regionHeader(_ name: String) -> some View {
        Text(name.uppercased())
            .font(.custom("Usual-Medium", size: 10, relativeTo: .caption2))
            .tracking(1.6)
            .foregroundColor(.darkBlue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .accessibilityLabel(name)
            .accessibilityAddTraits(.isHeader)
    }

    private func row(_ option: TimeZoneOption, at clock: DateComponents) -> some View {
        TimeZoneOptionRow(option: option, wallClock: clock, isChosen: option.identifier == entry.timeZoneIdentifier) {
            choose(option.identifier)
        }
        .id(option.identifier)
    }
}
