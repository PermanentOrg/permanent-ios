//
//  TextViewModifiers.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 23.06.2023.

import SwiftUI

fileprivate enum FontName: String {
    case openSansRegular = "OpenSans-Regular"
}

fileprivate enum FontSize: CGFloat {
    case xxxSmall = 12.0
    case xxSmall = 13.0
    case xSmall = 14.0
    case small = 15.0
    case regular = 16.0
    case medium = 18.0
    case large = 20.0
}

struct SmallXXRegularTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansRegular.rawValue,
                             size: FontSize.xxSmall.rawValue,
                             relativeTo: .largeTitle))
    }
}
