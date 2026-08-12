//
//  ActivityHeaderRow.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import SwiftUI

/// "Uploading to Permanent" on the left, "3 of 5" on the right. Identical in the expanded
/// island and on the Lock Screen.
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
        // Pinned to 22pt; SwiftUI's own ~20.3 leaves the banner 3pt short of 160pt.
        // `minHeight`, not `height`, so the row still grows at larger text sizes.
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
