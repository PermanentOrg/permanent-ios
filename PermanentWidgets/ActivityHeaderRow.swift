//
//  ActivityHeaderRow.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import SwiftUI

/// "Uploading to Permanent" on the left, "3 of 5" on the right — 26269:50897 in the
/// expanded island, 26269:50896 on the Lock Screen. Identical in both.
struct ActivityHeaderRow: View {
    let title: String
    let trailing: String

    var body: some View {
        HStack(alignment: .top, spacing: UploadActivityStyle.headerSpacing) {
            Text(title)
                .foregroundStyle(UploadActivityStyle.primaryLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(trailing)
                .foregroundStyle(UploadActivityStyle.secondaryLabel)
                .monospacedDigit()
                .fixedSize(horizontal: true, vertical: false)
        }
        .font(UploadActivityStyle.headerFont)
        .tracking(UploadActivityStyle.headerTracking)
        .lineLimit(1)
        // Figma pins this row to 22pt (`h-[22px]` on 26269:50898); SwiftUI's own line
        // height for 17pt is ~20.3, which left the Lock Screen banner 3pt short of its
        // 160pt. `minHeight` rather than `height` so the row still grows at larger
        // accessibility text sizes instead of clipping.
        .frame(minHeight: UploadActivityStyle.headerLineHeight)
    }
}

#if DEBUG
#Preview("Header row, including an overlong title") {
    VStack(spacing: 20) {
        ActivityHeaderRow(title: "Uploading to Permanent", trailing: "3 of 5")
        ActivityHeaderRow(title: "Processing Uploaded Files", trailing: "12 of 340")
        ActivityHeaderRow(title: "A title long enough to need truncating here", trailing: "1 of 2")
    }
    .padding()
    .frame(width: 294)
    .background(Color.black)
}
#endif
