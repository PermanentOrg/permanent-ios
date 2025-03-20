//
//  CustomListItemView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.12.2023.

import SwiftUI

/// A SwiftUI view that represents a customizable list item with a consistent design pattern.
/// 
/// This view creates a horizontal layout that includes:
/// - A leading icon/image
/// - A content section with title and description
/// - An optional badge (for highlighting new or special items)
/// - A trailing chevron indicator
/// 
/// The view is designed for use in lists where each item needs to display structured information
/// in a visually appealing way. It's particularly useful for navigation menus, settings pages,
/// or any list where items need to show both primary and secondary information.
/// 
/// - Parameters:
///   - image: The leading image/icon to display (24x24 points, automatically tinted)
///   - titleText: The primary text displayed in a semi-bold style
///   - descText: Secondary text shown below the title (limited to 2 lines)
///   - showBadge: When true, displays a badge next to the title. Defaults to `false`
///   - badgeText: Custom text for the badge. Defaults to "NEW" if not specified
///   - badgeColor: Custom color for the badge. Defaults to yellow if not specified
///
/// # Example Usage
/// ```swift
/// // Basic usage
/// CustomListItemView(
///     image: Image(systemName: "folder.fill"),
///     titleText: "Documents",
///     descText: "Access all your stored documents"
/// )
///
/// // With badge
/// CustomListItemView(
///     image: Image(systemName: "gift.fill"),
///     titleText: "Special Offer",
///     descText: "Limited time storage upgrade available",
///     showBadge: true,
///     badgeText: "NEW",
///     badgeColor: .red
/// )
/// ```
///
/// The view automatically handles proper spacing, alignment, and color styling
/// to maintain consistency across the app's interface.


struct CustomListItemView: View {
    var image: Image
    var titleText: String
    var descText: String
    var showBadge: Bool = false
    var badgeText: String?
    var badgeColor: Color?
    var showToggle: Bool = false
    
    @Binding var isSelected: Bool
    @Binding var isToggleOn: Bool
    
    init(image: Image, titleText: String, descText: String,
         showBadge: Bool = false, badgeText: String? = nil, badgeColor: Color? = nil,
         showToggle: Bool = false, isToggleOn: Binding<Bool> = .constant(false), isSelected: Binding<Bool> = .constant(false)) {
        self.image = image
        self.titleText = titleText
        self.descText = descText
        self.showBadge = showBadge
        self.badgeText = badgeText
        self.badgeColor = badgeColor
        self.showToggle = showToggle
        self._isToggleOn = isToggleOn
        self._isSelected = isSelected
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if !(Constants.Design.isPhone) {
                Rectangle()
                    .frame(width: 4)
                    .foregroundColor(isSelected ? Color.blue900 : Color.clear)
            }
            HStack(alignment: .top, spacing: 24) {
                image
                    .resizable()
                    .foregroundColor(.blue900)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .padding(.leading, 10)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Text(titleText)
                            .textStyle(UsualSmallXMediumTextStyle())
                            .foregroundColor(.blue900)
                        if showBadge {
                            NewBadgeView(badgeText: badgeText ?? "NEW", badgeColor: badgeColor ?? .yellow)
                                .transition(.opacity)
                        } else {
                            NewBadgeView(badgeText: "", badgeColor: .clear)
                                .opacity(0)
                        }
                    }
                    Text(descText)
                        .textStyle(UsualSmallXXXRegularTextStyle())
                        .foregroundColor(.blue400)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if showToggle {
                    CustomToggleView(isOn: $isToggleOn, height: 24, width: 36)
                        .padding(.trailing, 10)
                } else {
                    Image(.settingsNextArrowIcon)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue400)
                        .padding(.trailing, 10)
                }
            }
            .padding(10)
        }
    }
}
