//
//  DestinationFolderCard.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import SwiftUI

/// The destination folder row — 26269:50873 (expanded) / 26269:50850 (Lock Screen):
/// brand mark on the left, folder glyph on the right, and the folder's name and item
/// count centred across the whole row.
///
/// Figma centres that text block absolutely (`left-1/2`, outside the flex flow) rather
/// than as a third stack child, so it is an `.overlay` here — a third `HStack` child
/// would centre it in the gap between the glyphs instead, which sits several points off.
/// The overlay is inset past the glyphs so a long folder name truncates rather than
/// running underneath them.
///
/// Every field degrades independently. An upload re-queued from a queue persisted
/// before `FolderInfo` carried these knows none of them, and the card shows what it has
/// rather than inventing the rest.
struct DestinationFolderCard: View {
    /// Empty drops the title line.
    let folderName: String
    /// `nil` drops the count, rather than printing a number that only counts this batch.
    let itemCount: Int?
    /// `nil` drops the badge. Not defaulted to Private: this label is a claim about who
    /// can see the upload, and a confidently wrong one is worse than none.
    let isShared: Bool?
    /// Height of the two glyphs. The row itself sizes to its tallest child, so at large
    /// accessibility text sizes it grows instead of clipping.
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

    /// "32 items • Private" — 26269:50893. One string with two colours, built as an
    /// `AttributedString` so the count and badge share a baseline. Either half can be
    /// absent, and the separator appears only when both are present.
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

    /// Horizontal inset that keeps the centred text clear of both glyphs. The 8pt gap
    /// is ours, not the design's — Figma never has a name long enough to collide.
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
