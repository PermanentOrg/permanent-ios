//
//  TextViewModifiers.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 23.06.2023.

import SwiftUI

fileprivate enum FontName: String {
    case openSansRegular = "OpenSans-Regular"
    case openSansSemiBold = "OpenSans-SemiBold"
    case openSansBold = "OpenSans-Bold"
}

fileprivate enum FontSize: CGFloat {
    case xxxxxSmall = 10.0
    case xxxxSmall = 11.0
    case xxxSmall = 12.0
    case xxSmall = 13.0
    case xSmall = 14.0
    case small = 15.0
    case regular = 16.0
    case medium = 18.0
    case large = 20.0
}

struct SmallXXXXXSemiBoldTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansSemiBold.rawValue,
                             size: FontSize.xxxxxSmall.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct SmallXXXXXRegularTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansRegular.rawValue,
                             size: FontSize.xxxxxSmall.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct SmallXXRegularTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansRegular.rawValue,
                             size: FontSize.xxSmall.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct SmallXXXRegularTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansRegular.rawValue,
                             size: FontSize.xxxSmall.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct SmallBoldTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansBold.rawValue,
                             size: FontSize.small.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct SmallSemiBoldTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansSemiBold.rawValue,
                             size: FontSize.small.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct SmallRegularTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansRegular.rawValue,
                             size: FontSize.small.rawValue,
                             relativeTo: .largeTitle))
    }
}
