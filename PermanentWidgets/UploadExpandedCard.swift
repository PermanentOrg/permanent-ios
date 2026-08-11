//
//  UploadExpandedCard.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import SwiftUI

/// The expanded Dynamic Island at maximum height — 26269:50872.
///
/// No top padding: this renders in `DynamicIslandExpandedRegion(.bottom)`, which
/// already starts below the sensor housing. The design's 32pt top inset is measured
/// from the island's own top edge, and the housing occupies that band. Confirmed on
/// device — content lands ~48pt below the island top and reads correctly.
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
/// 374 × 174 is the design's frame. The extra top padding and the horizontal
/// `systemRegionInset` stand in for what the real island applies, so this matches what
/// ships rather than what the view alone produces.
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
