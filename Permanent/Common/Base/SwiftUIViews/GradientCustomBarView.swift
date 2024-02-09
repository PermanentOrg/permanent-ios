//
//  GradientCustomBarView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.12.2023.

import SwiftUI

struct GradientProgressBarView: View {
    var value: String
    var maxValue: String
    var sizeRatio: Double
    var colorScheme: ColorSchemeForProgressBar
    var font: FontType = .openSans
    @State private var redraw = UUID()
    
    var body: some View {
        LazyVStack(spacing: 16) {
            HStack {
                HStack(spacing: 0) {
                    UsedValueText(font: font, text: "\(value) ", colorScheme: colorScheme)
                    if value.isNotEmpty {
                        UsedText(font: font, colorScheme: colorScheme)
                    }
                }
                Spacer()
                MaxValueText(font: font, text: "\(maxValue)", colorScheme: colorScheme)
            }
            .padding(.horizontal)
            switch colorScheme {
            case .lightWithGradientBar:
                ProgressView(value: sizeRatio)
                    .progressViewStyle(CustomBarProgressGradientStyle(colorScheme: .lightWithGradientBar, height: 8, cornerRadius: 3))
                    .frame(height: 12)
                    .padding(.horizontal)
                    .id(redraw)
            case .gradientWithWhiteBar:
                ProgressView(value: sizeRatio)
                    .progressViewStyle(CustomBarProgressStyle(color: .white, height: 8, cornerRadius: 3))
                    .frame(height: 12)
                    .padding(.horizontal)
                    .id(redraw)
            }
        }
        .onChange(of: sizeRatio, perform: { newValue in
            updateRedraw()
        })
        .frame(maxHeight: colorScheme.frameHeightSize)
        .background(colorScheme.backgroundColor)
        .cornerRadius(12)
        .padding(colorScheme == .gradientWithWhiteBar ? 16  : 0)
    }
    
    func updateRedraw() {
        redraw = UUID()
    }
}

enum ColorSchemeForProgressBar {
    case lightWithGradientBar
    case gradientWithWhiteBar

    var backgroundColor: LinearGradient {
        switch self {
        case .lightWithGradientBar:
            return Gradient.whiteGradient
        case .gradientWithWhiteBar:
            return Gradient.purpleYellowGradient
        }
    }
    var barColor: LinearGradient {
        switch self {
        case .lightWithGradientBar:
            return Gradient.purpleYellowGradient
        case .gradientWithWhiteBar:
            return Gradient.whiteGradient
        }
    }
    
    var textColor: Color {
        switch self {
        case .lightWithGradientBar:
            return Color.black
        case .gradientWithWhiteBar:
            return Color.white
        }
    }
    
    var textSecondaryColor: Color {
        switch self {
        case .lightWithGradientBar:
            return Color.middleGray
        case .gradientWithWhiteBar:
            return Color.white
        }
    }
    
    var frameHeightSize: CGFloat {
        switch self {
        case .lightWithGradientBar:
            return 60
        case .gradientWithWhiteBar:
            return 72
        }
    }
}

fileprivate struct UsedValueText: View {
    var font: FontType
    var text: String
    var colorScheme: ColorSchemeForProgressBar
    
    var body: some View {
        if font == .usual {
            Text(text)
                .textStyle(UsualSmallXXXSemiBoldTextStyle())
                .foregroundColor(colorScheme.textColor)
        } else {
            Text(text)
                .textStyle(SmallXXXSemiBoldTextStyle())
                .foregroundColor(colorScheme.textColor)
        }
    }
}

fileprivate struct UsedText: View {
    var font: FontType
    var text: String = "used"
    var colorScheme: ColorSchemeForProgressBar
    
    var body: some View {
        if font == .usual {
            Text(text)
                .textStyle(UsualSmallXXXRegularTextStyle())
                .foregroundColor(colorScheme.textSecondaryColor)
        } else {
            Text(text)
                .textStyle(SmallXXXRegularTextStyle())
                .foregroundColor(colorScheme.textSecondaryColor)
        }
    }
}

fileprivate struct MaxValueText: View {
    var font: FontType
    var text: String
    var colorScheme: ColorSchemeForProgressBar
    
    var body: some View {
        if font == .usual {
            Text(text)
                .textStyle(UsualSmallXXXSemiBoldTextStyle())
                .foregroundColor(colorScheme.textColor)
        } else {
            Text(text)
                .textStyle(SmallXXXSemiBoldTextStyle())
                .foregroundColor(colorScheme.textColor)
        }
    }
}
