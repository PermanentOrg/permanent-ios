//
//  UploadLockScreenBanner.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import SwiftUI

/// The Lock Screen banner — 26269:50826 / 26269:50849. 24pt padding on all sides and
/// 16pt between the three blocks add up to the design's 160pt height exactly, so no
/// explicit height is set and terminal states can size themselves.
///
/// The background is not drawn here — see `BannerBackground`, which tints the system
/// container on iOS 26 rather than replacing it.
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
/// 382 × 160 is the design's frame, so this can be diffed against the Figma render.
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
