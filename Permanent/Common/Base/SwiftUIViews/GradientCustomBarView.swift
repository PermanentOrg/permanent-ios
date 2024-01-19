//
//  GradientCustomBarView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.12.2023.

import SwiftUI

struct GradientProgressBarView: View {
    @Binding var value: String
    @Binding var maxValue: String
    @Binding var sizeRatio: Double
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 0) {
                    Text("\(value) ")
                        .textStyle(SmallXXXSemiBoldTextStyle())
                        .foregroundColor(.white)
                    if value.isNotEmpty {
                        Text("used")
                            .textStyle(SmallXXXRegularTextStyle())
                            .foregroundColor(.white)
                    }
                }
                Spacer()
                Text("\(maxValue)")
                    .textStyle(SmallXXXSemiBoldTextStyle())
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            if sizeRatio != .zero {
                ProgressView(value: sizeRatio)
                    .progressViewStyle(CustomBarProgressStyle(color: .white, height: 8, cornerRadius: 3))
                    .frame(height: 12)
                    .padding(.horizontal)
            } else {
                ProgressView(value: 0.0)
                    .progressViewStyle(CustomBarProgressStyle(color: .white, height: 8, cornerRadius: 3))
                    .frame(height: 12)
                    .padding(.horizontal)
            }
        }
        .frame(maxHeight: 72)
        .background(Gradient.purpleYellowGradient)
        .cornerRadius(12)
        .padding(16)
    }
}
