//
//  UploadExpandedCard.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import SwiftUI

/// The expanded island at maximum height. No top padding: `.bottom` already starts below the
/// sensor housing, which occupies the design's 32pt top inset.
struct UploadExpandedCard: View {
    let display: UploadActivityDisplay

    var body: some View {
        VStack(alignment: .leading, spacing: UploadActivityStyle.Expanded.spacing) {
            ActivityHeaderRow(title: display.headerTitle, trailing: display.counter)
            GradientProgressBar(progress: display.progress, fill: display.barFill)
            DestinationFolderCard(
                folderName: display.folderName,
                itemCount: display.folderItemCount,
                isShared: display.folderIsShared,
                glyphHeight: UploadActivityStyle.Expanded.folderRowHeight
            )
        }
        .padding(.horizontal, UploadActivityStyle.Expanded.regionHorizontalPadding)
        .padding(.bottom, UploadActivityStyle.Expanded.verticalPadding)
        .dynamicTypeSize(...UploadActivityStyle.maxDynamicTypeSize)
    }
}

#if DEBUG
/// 374 × 174 is the design's size; the extra insets stand in for the real island's own, so
/// this matches what ships.
#Preview("Expanded island — 374×174") {
    UploadExpandedCard(display: .previewUploading)
        .padding(.top, UploadActivityStyle.Expanded.verticalPadding)
        .padding(.horizontal, UploadActivityStyle.Expanded.systemRegionInset)
        .frame(width: 374, height: 174)
        .background(Color.black)
        .clipShape(.rect(cornerRadius: 47))
        .padding()
}

#Preview("Expanded island — folder unknown") {
    UploadExpandedCard(display: .previewUnknownFolder)
        .padding(.top, UploadActivityStyle.Expanded.verticalPadding)
        .padding(.horizontal, UploadActivityStyle.Expanded.systemRegionInset)
        .frame(width: 374, height: 174)
        .background(Color.black)
        .clipShape(.rect(cornerRadius: 47))
        .padding()
}
#endif
