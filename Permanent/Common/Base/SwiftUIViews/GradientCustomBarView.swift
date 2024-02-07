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
    @State private var redraw = UUID()
    
    var body: some View {
        LazyVStack(spacing: 16) {
            HStack {
                HStack(spacing: 0) {
                    Text("\(value) ")
                        .textStyle(SmallXXXSemiBoldTextStyle())
                        .foregroundColor(colorScheme.textColor)
                    if value.isNotEmpty {
                        Text("used")
                            .textStyle(SmallXXXRegularTextStyle())
                            .foregroundColor(colorScheme.textSecondaryColor)
                    }
                }
                Spacer()
                Text("\(maxValue)")
                    .textStyle(SmallXXXSemiBoldTextStyle())
                    .foregroundColor(colorScheme.textColor)
            }
            .padding(.horizontal)
            switch colorScheme {
            case .lightWithGradientBar:
                ProgressView(value: sizeRatio)
                    .progressViewStyle(CustomBarProgressGradientStyle(colorScheme: .lightWithGradientBar, height: 8, cornerRadius: 3))
                    .frame(height: 12)
                    .padding(.horizontal)
                    .id(redraw)
            case .GradientWithWhiteBar:
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
        .padding(colorScheme == .GradientWithWhiteBar ? 16  : 0)
    }
    
    func updateRedraw() {
        redraw = UUID()
    }
}

enum ColorSchemeForProgressBar {
    case lightWithGradientBar
    case GradientWithWhiteBar

    var backgroundColor: LinearGradient {
        switch self {
        case .lightWithGradientBar:
            return Gradient.whiteGradient
        case .GradientWithWhiteBar:
            return Gradient.purpleYellowGradient
        }
    }
    var barColor: LinearGradient {
        switch self {
        case .lightWithGradientBar:
            return Gradient.purpleYellowGradient
        case .GradientWithWhiteBar:
            return Gradient.whiteGradient
        }
    }
    
    var textColor: Color {
        switch self {
        case .lightWithGradientBar:
            return Color.black
        case .GradientWithWhiteBar:
            return Color.white
        }
    }
    
    var textSecondaryColor: Color {
        switch self {
        case .lightWithGradientBar:
            return Color.middleGray
        case .GradientWithWhiteBar:
            return Color.white
        }
    }
    
    var frameHeightSize: CGFloat {
        switch self {
        case .lightWithGradientBar:
            return 60
        case .GradientWithWhiteBar:
            return 72
        }
    }
}
