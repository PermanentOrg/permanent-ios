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
    @State private var redraw = UUID()
    
    var body: some View {
        LazyVStack(spacing: 16) {
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
            ProgressView(value: sizeRatio)
                .progressViewStyle(CustomBarProgressStyle(color: .white, height: 8, cornerRadius: 3))
                .frame(height: 12)
                .padding(.horizontal)
                .id(redraw)
        }
        .onChange(of: sizeRatio, perform: { newValue in
            updateRedraw()
        })
        .frame(maxHeight: 72)
        .background(Gradient.purpleYellowGradient)
        .cornerRadius(12)
        .padding(16)
    }
    
    func updateRedraw() {
        redraw = UUID()
    }
}
