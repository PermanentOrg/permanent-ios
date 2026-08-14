//
//  DestinationFolderCard.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import SwiftUI

/// Brand mark left, folder glyph right, name and count centred across the full row — an
/// `.overlay`, since a third `HStack` child would centre in the gap instead.
struct DestinationFolderCard: View {
    /// Empty drops the title line.
    let folderName: String
    /// `nil` drops the count, rather than printing a number that only counts this batch.
    let itemCount: Int?
    /// `nil` drops the badge, rather than defaulting to Private — a claim about who can see
    /// the upload, where a confidently wrong one is worse than none.
    let isShared: Bool?
    /// Height of the two glyphs. The row sizes to its tallest child, so large text grows it.
    let glyphHeight: CGFloat

    private var badgeText: String? {
        guard let isShared else { return nil }
        return isShared ? "Shared" : "Private"
    }

    private var badgeColor: Color {
        isShared == true ? UploadActivityStyle.sharedBadge : UploadActivityStyle.privateBadge
    }

    private var countText: String? {
        guard let itemCount else { return nil }
        return "\(itemCount) item\(itemCount == 1 ? "" : "s")"
    }

    /// "32 items • Private" — two colours in one string, so the halves share a baseline.
    /// Either half can be absent; the separator appears only when both are present.
    private var subtitle: AttributedString? {
        func run(_ string: String, _ color: Color) -> AttributedString {
            var run = AttributedString(string)
            run.foregroundColor = color
            return run
        }
        let secondary = UploadActivityStyle.secondaryLabel
        switch (countText, badgeText) {
        case let (count?, badge?):
            return run("\(count) • ", secondary) + run(badge, badgeColor)
        case let (count?, nil):
            return run(count, secondary)
        case let (nil, badge?):
            return run(badge, badgeColor)
        case (nil, nil):
            return nil
        }
    }

    private var accessibilityDescription: String {
        let parts = [
            folderName.isEmpty ? nil : "Destination \(folderName)",
            countText,
            badgeText
        ].compactMap { $0 }
        return parts.isEmpty ? "Destination folder" : parts.joined(separator: ", ")
    }

    /// Keeps the centred text clear of both glyphs. The 8pt gap is not a design value; it is
    /// there so a long folder name truncates rather than colliding.
    private var glyphClearance: CGFloat {
        let mark = glyphHeight * UploadActivityStyle.brandMarkAspect
        let folder = glyphHeight * UploadActivityStyle.folderGlyphAspect
        return max(mark, folder) + 8
    }

    var body: some View {
        HStack(spacing: 0) {
            BrandMark(height: glyphHeight)
            Spacer(minLength: 0)
            DestinationFolderGlyph(height: glyphHeight)
        }
        .frame(maxWidth: .infinity)
        .overlay {
            VStack(spacing: UploadActivityStyle.folderTextSpacing) {
                if !folderName.isEmpty {
                    Text(folderName)
                        .font(UploadActivityStyle.emphasisFont)
                        .tracking(UploadActivityStyle.emphasisTracking)
                        .foregroundStyle(UploadActivityStyle.primaryLabel)
                }
                if let subtitle {
                    Text(subtitle)
                        .font(UploadActivityStyle.detailFont)
                        .tracking(UploadActivityStyle.detailTracking)
                }
            }
            .lineLimit(1)
            .padding(.horizontal, glyphClearance)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityDescription)
        }
    }
}

#if DEBUG
#Preview("Folder card, full through fully unknown") {
    VStack(spacing: 20) {
        DestinationFolderCard(
            folderName: "Northern Lights 2022",
            itemCount: 32,
            isShared: false,
            glyphHeight: UploadActivityStyle.Expanded.folderRowHeight
        )
        DestinationFolderCard(
            folderName: "Shared with the family, a long one",
            itemCount: 1,
            isShared: true,
            glyphHeight: UploadActivityStyle.Expanded.folderRowHeight
        )
        // Count unknown — badge only.
        DestinationFolderCard(
            folderName: "Mobile Uploads",
            itemCount: nil,
            isShared: false,
            glyphHeight: UploadActivityStyle.Expanded.folderRowHeight
        )
        // Nothing known — glyphs only, no invented values.
        DestinationFolderCard(
            folderName: "",
            itemCount: nil,
            isShared: nil,
            glyphHeight: UploadActivityStyle.Expanded.folderRowHeight
        )
    }
    .padding()
    .frame(width: 294)
    .background(Color.black)
}
#endif
