//
//  RedesignArchivesWidget.swift
//  Permanent
//
//  Stage 6 — the populated "Archives" widget on the My Dashboard tab.
//  A white `RedesignWidgetCard` listing the account's real archives, each as a
//  gradient rounded-square initials tile + the archive name (with the
//  distinctive middle word in Medium, e.g. "The Robert Friedman Archive") + a
//  trailing chevron. Below the rows, a thin divider and the dark-blue gradient
//  "Create an Archive" button (reuses `RedesignPrimaryButton`).
//
//  Pure presentational view — data + actions are injected by the host
//  (`RedesignHomeDashboardView`). Only reachable when
//  `DashboardRedesign.isEnabled`.
//

import SwiftUI

/// One archive row in the Archives widget.
///
/// `fullName` is the complete display name (e.g. "The Robert Friedman Archive").
/// `initials` are precomputed (1–2 letters). `accent` is the tile gradient so
/// rows can vary their color if desired.
struct RedesignArchiveItem: Identifiable {
    let id: Int
    let fullName: String
    let initials: String
    let accent: LinearGradient

    init(id: Int,
         fullName: String,
         initials: String,
         accent: LinearGradient = RedesignGradient.iconPurpleOrange) {
        self.id = id
        self.fullName = fullName
        self.initials = initials
        self.accent = accent
    }
}

struct RedesignArchivesWidget: View {
    let archives: [RedesignArchiveItem]
    var onSelect: (RedesignArchiveItem) -> Void = { _ in }
    var onCreate: () -> Void = {}

    var body: some View {
        RedesignWidgetCard {
            VStack(spacing: 24) {
                ForEach(archives) { archive in
                    Button { onSelect(archive) } label: {
                        row(archive)
                    }
                    .buttonStyle(.plain)
                }

                if !archives.isEmpty {
                    Rectangle()
                        .fill(RedesignColor.whiteGray)
                        .frame(height: 1)
                }

                RedesignPrimaryButton(
                    title: "Create an Archive",
                    gradient: RedesignGradient.primaryButtonD,
                    action: onCreate
                )
            }
            .padding(24)
        }
    }

    // MARK: - Row

    private func row(_ archive: RedesignArchiveItem) -> some View {
        HStack(spacing: 16) {
            initialsTile(archive)

            attributedName(for: archive.fullName)
                .font(.custom(FontName.usualRegular.rawValue, fixedSize: 14))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(RedesignColor.blue300)
                .frame(width: 24, height: 24)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    /// 40×40 rounded-square (radius 6) gradient tile with a small white "switcher"
    /// notch at the top and the centered initials, matching the design.
    private func initialsTile(_ archive: RedesignArchiveItem) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(archive.accent)

            // White notch near the top edge (the archive-switcher cue).
            VStack {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 16, height: 2)
                    .padding(.top, 6)
                Spacer()
            }

            Text(archive.initials)
                .font(.custom(FontName.usualMedium.rawValue, fixedSize: 12))
                .foregroundColor(.white)
        }
        .frame(width: 40, height: 40)
    }

    /// Builds the "The {middle} {suffix}" display string where the distinctive
    /// middle portion is rendered in Medium #131B4A and the rest in Regular
    /// #5A5F80, matching the design (e.g. "The **Robert Friedman** Archive").
    private func attributedName(for fullName: String) -> Text {
        let regular = RedesignColor.blue600
        let medium = RedesignColor.darkBlue

        let words = fullName.split(separator: " ").map(String.init)

        // Pattern: leading "The" + … + trailing "Archive".
        let hasThe = words.first?.lowercased() == "the"
        let hasArchive = words.last?.lowercased() == "archive"

        guard hasThe || hasArchive, words.count >= 2 else {
            // Fallback: emphasize the whole name in Medium.
            return Text(fullName)
                .font(.custom(FontName.usualMedium.rawValue, fixedSize: 14))
                .foregroundColor(medium)
        }

        let startIndex = hasThe ? 1 : 0
        let endIndex = hasArchive ? words.count - 1 : words.count
        let middle = words[startIndex..<endIndex].joined(separator: " ")

        var result = Text("")
        if hasThe {
            result = result + Text("The ")
                .font(.custom(FontName.usualRegular.rawValue, fixedSize: 14))
                .foregroundColor(regular)
        }
        result = result + Text(middle)
            .font(.custom(FontName.usualMedium.rawValue, fixedSize: 14))
            .foregroundColor(medium)
        if hasArchive {
            result = result + Text(" Archive")
                .font(.custom(FontName.usualRegular.rawValue, fixedSize: 14))
                .foregroundColor(regular)
        }
        return result
    }
}

#Preview {
    ScrollView {
        RedesignArchivesWidget(
            archives: [
                RedesignArchiveItem(id: 1, fullName: "The Robert Friedman Archive", initials: "RF"),
                RedesignArchiveItem(id: 2, fullName: "The Photography Archive", initials: "P"),
                RedesignArchiveItem(id: 3, fullName: "The Family Farm Archive", initials: "FF")
            ]
        )
        .padding(24)
    }
    .background(RedesignColor.whiteGray)
}
