//
//  CustomListItemView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.12.2023.

import SwiftUI

/// A list row: leading icon, title and description, an optional badge, and a trailing chevron.
/// The description is limited to two lines; the badge defaults to a yellow "NEW".


struct CustomListItemView: View {
    var image: Image
    var titleText: String
    var descText: String
    var showBadge: Bool = false
    var badgeText: String?
    var badgeColor: Color?
    var showToggle: Bool = false
    var showRectangle: Bool
    
    @Binding var isSelected: Bool
    @Binding var isToggleOn: Bool
    
    init(image: Image, titleText: String, descText: String,
         showBadge: Bool = false, badgeText: String? = nil, badgeColor: Color? = nil,
         showToggle: Bool = false, isToggleOn: Binding<Bool> = .constant(false), isSelected: Binding<Bool> = .constant(false), showRectangle: Bool = true) {
        self.image = image
        self.titleText = titleText
        self.descText = descText
        self.showBadge = showBadge
        self.badgeText = badgeText
        self.badgeColor = badgeColor
        self.showToggle = showToggle
        self._isToggleOn = isToggleOn
        self._isSelected = isSelected
        self.showRectangle = showRectangle
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if !(Constants.Design.isPhone) && showRectangle {
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
