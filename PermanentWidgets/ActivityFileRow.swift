//
//  ActivityFileRow.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import SwiftUI

/// Current file name and percentage. Lock Screen only. Tail truncation, not middle: the start of
/// a name is what distinguishes files in a batch, even though the extension is lost.
struct ActivityFileRow: View {
    let fileName: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: UploadActivityStyle.LockScreen.fileRowSpacing) {
            Text(fileName)
                .font(UploadActivityStyle.detailFont)
                .tracking(UploadActivityStyle.detailTracking)
                .foregroundStyle(UploadActivityStyle.secondaryLabel)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(detail)
                .font(UploadActivityStyle.emphasisFont)
                .tracking(UploadActivityStyle.emphasisTracking)
                .foregroundStyle(UploadActivityStyle.primaryLabel)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

#if DEBUG
#Preview("File row, short and truncating names") {
    VStack(spacing: 20) {
        ActivityFileRow(
            fileName: "arctic-fox-4366x3010-northern-hemisphere-animation.heic",
            detail: "65%"
        )
        ActivityFileRow(fileName: "IMG_1600.jpeg", detail: "8%")
        ActivityFileRow(fileName: "3 uploaded, 2 failed", detail: "2 failed")
    }
    .padding()
    .frame(width: 334)
    .background(Color.black)
}
#endif
