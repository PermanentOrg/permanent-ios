//
//  TextModifiers.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 16.05.2023.
//  Copyright © 2023 Victory Square Partners. All rights reserved.
//

import SwiftUI

enum ThemeFontName: String {
    case openSansBold = "OpenSans-Bold"
    case openSansBoldItalic = "OpenSans-BoldItalic"
    case openSansExtraBold = "OpenSans-ExtraBold"
    case openSansExtraBoldItalic = "OpenSans-ExtraBoldItalic"
    case openSansItalic = "OpenSans-Italic"
    case openSansLight = "OpenSans-Light"
    case openSansLightItalic = "OpenSans-LightItalic"
    case openSansRegular = "OpenSans-Regular"
    case openSansSemiBold = "OpenSans-SemiBold"
    case openSansSemiBoldItalic = "OpenSans-SemiBoldItalic"
}

enum ThemeFontSize: CGFloat {
    case xxSmall = 12.0
    case xSmall = 13.0
    case small = 14.0
    case regular = 15.0
    case medium = 16.0
    case medium2 = 17.0
    case large = 18.0
    case xLarge = 21.0
    case xxLarge = 24.0
    case xxxLarge = 27.0
}

struct OpenSansTypography: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(ThemeFontName.openSansRegular.rawValue,
                             fixedSize: 8.0))
    }
}

struct OpenSansXSmall: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(ThemeFontName.openSansRegular.rawValue,
                             fixedSize: ThemeFontSize.xSmall.rawValue))
    }
}

struct OpenSansSemiBoldXXSmall: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(ThemeFontName.openSansSemiBold.rawValue,
                             fixedSize: ThemeFontSize.xxSmall.rawValue))
    }
}

struct OpenSansSemiBoldXSmall: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(ThemeFontName.openSansSemiBold.rawValue,
                             fixedSize: ThemeFontSize.xSmall.rawValue))
    }
}

struct OpenSansSemiBoldRegular: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(ThemeFontName.openSansSemiBold.rawValue,
                             fixedSize: ThemeFontSize.regular.rawValue))
    }
}
