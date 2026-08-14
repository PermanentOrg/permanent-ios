//
//  DestinationFolderGlyph.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import SwiftUI

/// The destination folder glyph. Height-first for the same reason as `BrandMark`.
struct DestinationFolderGlyph: View {
    let height: CGFloat

    var body: some View {
        Image(.destinationFolder)
            .resizable()
            .frame(width: height * UploadActivityStyle.folderGlyphAspect, height: height)
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Folder glyph at each design size") {
    HStack(spacing: 24) {
        DestinationFolderGlyph(height: UploadActivityStyle.LockScreen.folderRowHeight)
        DestinationFolderGlyph(height: UploadActivityStyle.Expanded.folderRowHeight)
    }
    .padding()
    .background(Color.black)
}
#endif
