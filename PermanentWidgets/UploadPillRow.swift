//
//  UploadPillRow.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import SwiftUI

/// The expanded island at minimum height — 26268:46410. Used for the statuses the
/// design does not give a folder card to (paused, processing, completed, failed): brand
/// mark, an emphasised status word with a de-emphasised count, and the ring.
///
/// Figma draws this frame's content vertically centred in an 86pt box that the sensor
/// housing overlaps, which cannot render. Here it sits below the housing instead, so the
/// row reads slightly lower and taller than the frame — everything inside it matches.
struct UploadPillRow: View {
    let display: UploadActivityDisplay

    /// "**Uploading** • 4 of 6" — 26268:46411. The emphasised status word and the
    /// de-emphasised count are one string carrying two fonts and two colours, so they
    /// sit on a shared baseline.
    private var label: AttributedString {
        var word = AttributedString(display.statusWord)
        word.font = UploadActivityStyle.headerEmphasisFont
        word.foregroundColor = UploadActivityStyle.primaryLabel

        var detail = AttributedString(display.pillDetail)
        detail.font = UploadActivityStyle.headerFont
        detail.foregroundColor = UploadActivityStyle.secondaryLabel

        return word + detail
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: UploadActivityStyle.Pill.iconSpacing) {
                BrandMark(height: UploadActivityStyle.Pill.markSize)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .tracking(UploadActivityStyle.headerTracking)
                    // Only paused has something for the user to do, so only paused gets a
                    // hint. It mirrors the Lock Screen's "Tap to resume" so the two
                    // presentations say the same thing.
                    if let hint = display.hint {
                        Text(hint)
                            .font(UploadActivityStyle.detailFont)
                            .tracking(UploadActivityStyle.detailTracking)
                            .foregroundStyle(UploadActivityStyle.secondaryLabel)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            Spacer(minLength: UploadActivityStyle.Pill.iconSpacing)
            UploadProgressRing(
                progress: display.progress,
                metrics: .pill,
                tint: display.ringTint,
                glyph: display.ringGlyph
            )
        }
        .padding(.leading, UploadActivityStyle.Pill.regionLeadingPadding)
        .padding(.trailing, UploadActivityStyle.Pill.regionTrailingPadding)
        .padding(.bottom, UploadActivityStyle.Pill.verticalPadding)
        .dynamicTypeSize(...UploadActivityStyle.maxDynamicTypeSize)
    }
}

#if DEBUG
/// 374 × 86 is the design's frame; the insets stand in for the real island's own.
#Preview("Pill row — 374×86") {
    UploadPillRow(display: .previewPaused)
        .padding(.top, UploadActivityStyle.Pill.verticalPadding)
        .padding(.horizontal, UploadActivityStyle.Expanded.systemRegionInset)
        .frame(width: 374, height: 86)
        .background(Color.black)
        .clipShape(.capsule)
        .padding()
}

#Preview("Collapsed island — 184×37.33") {
    HStack(spacing: 0) {
        BrandMark(height: UploadActivityStyle.Compact.markHeight)
        Spacer()
        UploadProgressRing(progress: 0.65, metrics: .compact)
    }
    .padding(.horizontal, 7)
    .frame(width: 184, height: 37.33)
    .background(Color.black)
    .clipShape(.capsule)
    .padding()
}
#endif
