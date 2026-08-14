//
//  UploadLockScreenBanner.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import SwiftUI

/// 24pt padding and 16pt between blocks add up to the design's 160pt, so no height is set
/// and terminal states size themselves. Background lives in `BannerBackground`.
struct UploadLockScreenBanner: View {
    let display: UploadActivityDisplay

    var body: some View {
        VStack(alignment: .leading, spacing: UploadActivityStyle.LockScreen.spacing) {
            VStack(alignment: .leading, spacing: UploadActivityStyle.LockScreen.textBlockSpacing) {
                ActivityHeaderRow(title: display.headerTitle, trailing: display.counter)
                ActivityFileRow(fileName: display.fileLine, detail: display.fileDetail)
            }
            GradientProgressBar(progress: display.progress, fill: display.barFill)
            DestinationFolderCard(
                folderName: display.folderName,
                itemCount: display.folderItemCount,
                isShared: display.folderIsShared,
                glyphHeight: UploadActivityStyle.LockScreen.folderRowHeight
            )
        }
        .padding(UploadActivityStyle.LockScreen.padding)
        .frame(maxWidth: .infinity)
        .dynamicTypeSize(...UploadActivityStyle.maxDynamicTypeSize)
    }
}

#if DEBUG
/// 382 × 160 is the design's size, so this can be diffed against the design directly.
#Preview("Lock Screen banner — 382×160") {
    UploadLockScreenBanner(display: .previewShared)
        .frame(width: 382)
        .background(
            ZStack {
                UploadActivityStyle.lockScreenBackground
                UploadActivityStyle.lockScreenScrim
            }
        )
        .clipShape(.rect(cornerRadius: UploadActivityStyle.lockScreenCornerRadius))
        .padding()
}
#endif
