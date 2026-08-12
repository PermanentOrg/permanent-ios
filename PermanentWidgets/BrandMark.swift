//
//  BrandMark.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import SwiftUI

/// The Permanent swirl. Drawn height-first, as the design lays it out, so the width always
/// follows the height.
struct BrandMark: View {
    let height: CGFloat

    var body: some View {
        Image(.permanentBrandMark)
            .resizable()
            .frame(width: height * UploadActivityStyle.brandMarkAspect, height: height)
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Brand mark at each design size") {
    HStack(spacing: 24) {
        BrandMark(height: UploadActivityStyle.Compact.markHeight)
        BrandMark(height: UploadActivityStyle.Pill.markSize)
        BrandMark(height: UploadActivityStyle.Expanded.folderRowHeight)
    }
    .padding()
    .background(Color.black)
}
#endif
