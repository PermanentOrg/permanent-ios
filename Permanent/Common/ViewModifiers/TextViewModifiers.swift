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
    case openSansItalic = "OpenSans-Italic"
    case usualRegular = "Usual-Regular"
    case usualMedium = "Usual-Medium"
    case usualBold = "Usual-Bold"
    case usualItalic = "Usual-Italic"
    case usualLight = "Usual-Light"
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
    case mediumLarge = 24.0
    case xLarge = 32.0
    case xxLarge = 56.0
}

enum FontType {
    case usual
    case openSans
}

struct UsualXLargeTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualRegular.rawValue,
                             size: FontSize.xLarge.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct UsualRegularMediumLargeTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualRegular.rawValue,
                             size: FontSize.mediumLarge.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct UsualMediumLargeTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualMedium.rawValue,
                             size: FontSize.mediumLarge.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct UsualXLargeLightTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualLight.rawValue,
                             size: FontSize.xLarge.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct UsualXXLargeLightTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualLight.rawValue,
                             size: FontSize.xxLarge.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct UsualXLargeBoldTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualBold.rawValue,
                             size: FontSize.xLarge.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct UsualXXLargeBoldTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualBold.rawValue,
                             size: FontSize.xxLarge.rawValue,
                             relativeTo: .largeTitle))
    }
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

struct UsualSmallXXXXXRegularTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualRegular.rawValue,
                             size: FontSize.xxxxxSmall.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct SmallXXXXXItalicTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansItalic.rawValue,
                             size: FontSize.xxxxxSmall.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct SmallXXXXRegularTextStyle: ViewModifier {
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

struct SmallXXSemiBoldTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansSemiBold.rawValue,
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

struct UsualSmallXXXRegularTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualRegular.rawValue,
                             size: FontSize.xxxSmall.rawValue,
                             relativeTo: .largeTitle))
    }
}


struct SmallXXXSemiBoldTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansSemiBold.rawValue,
                             size: FontSize.xxxSmall.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct UsualSmallXXXSemiBoldTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualMedium.rawValue,
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

struct RegularBoldTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansBold.rawValue,
                             size: FontSize.regular.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct SmallXRegularTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansRegular.rawValue,
                             size: FontSize.xSmall.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct UsualSmallXMediumTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualMedium.rawValue,
                             size: FontSize.xSmall.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct UsualSmallXRegularTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualRegular.rawValue,
                             size: FontSize.xSmall.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct SmallXSemiBoldTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansSemiBold.rawValue,
                             size: FontSize.xSmall.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct UsualSmallXSemiBoldTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualMedium.rawValue,
                             size: FontSize.xSmall.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct MediumSemiBoldTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansSemiBold.rawValue,
                             size: FontSize.medium.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct RegularTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansRegular.rawValue,
                             size: FontSize.regular.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct UsualRegularTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualRegular.rawValue,
                             size: FontSize.regular.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct UsualRegularMediumTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualMedium.rawValue,
                             size: FontSize.regular.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct UsualMediumTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualMedium.rawValue,
                             size: FontSize.medium.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct UsualMediumRegularTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualRegular.rawValue,
                             size: FontSize.medium.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct UsualLightRegularTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualLight.rawValue,
                             size: FontSize.regular.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct UsualXXLargeRegularTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.usualRegular.rawValue,
                             size: FontSize.xxLarge.rawValue,
                             relativeTo: .largeTitle))
    }
}

struct RegularSemiBoldTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.custom(FontName.openSansSemiBold.rawValue,
                             size: FontSize.regular.rawValue,
                             relativeTo: .largeTitle))
    }
}
