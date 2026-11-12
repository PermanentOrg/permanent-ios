//
//  RangeSideLabel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.11.2026.
//

import SwiftUI

/// The small caps label that heads one side of a range: "FROM" or "TO", at the leading edge.
struct RangeSideLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.custom("Usual-Regular", size: 10, relativeTo: .caption2))
            .tracking(1.6)
            .textCase(.uppercase)
            .foregroundColor(.darkBlue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}
