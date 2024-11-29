//
//  NewBadgeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.12.2023.

import SwiftUI

/// A view that displays a badge with a text and a color.
/// - Parameters:
///    - badgeText: The text to be displayed on the badge.
///    - badgeColor: The color of the badge.
///    - Returns: View
///  Example:
///  ```
///  NewBadgeView(badgeText: "New", badgeColor: .blue)
///  ```

struct NewBadgeView: View {
    var badgeText: String
    var badgeColor: Color
    
    init(badgeText: String, badgeColor: Color) {
        self.badgeText = badgeText
        self.badgeColor = badgeColor
    }
    
    var body: some View {
        HStack {
            if #available(iOS 16, *) {
                Text("\(badgeText)")
                    .textStyle(UsualSmallXXXXXMediumTextStyle())
                    .kerning(1.6)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
            } else {
                Text("\(badgeText)")
                    .textStyle(UsualSmallXXXXXMediumTextStyle())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
            }
        }
        .frame(height: 24)
        .padding(.horizontal, 8)
        .padding(.vertical, 0)
        .background(badgeColor)
        .cornerRadius(20)
    }
}
