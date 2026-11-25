//
//  FileMenuHeaderDetailLine.swift
//  Permanent
//
//  Created by Lucian Cerbu on 23.11.2026.
//

import SwiftUI

/// The "size • date" line under the item name in the item menu header.
struct FileMenuHeaderDetailLine: View {
    let size: String?
    let date: String

    /// Below this share of 12pt, the date text gives up and ends in "…".
    static let minimumScaleFactor: CGFloat = 0.8

    var body: some View {
        HStack(spacing: 8) {
            if let size {
                Text(size)
                    .fixedSize()
            }

            if size != nil && !date.isEmpty {
                Text("•")
                    .fixedSize()
            }

            if !date.isEmpty {
                // A date with a time and a zone is long; it shrinks a little before it wraps.
                Text(date)
                    .lineLimit(1)
                    .minimumScaleFactor(Self.minimumScaleFactor)
                    .layoutPriority(1)
            }
        }
        .font(.custom("Usual-Regular", size: 12))
        .foregroundColor(Color.blue400)
    }
}
