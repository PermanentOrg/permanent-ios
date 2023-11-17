//
//  CustomBarProgressStyle.swift
//  Permanent
//
//  Created by Lucian Cerbu on 31.10.2023.

import SwiftUI

/// Description: User for displaying a custom progress bar view
///     - Parameters:
///         - color: Set the color of the progress bar
///         - height: Set the height
///         - cornerRadius: Set the corner radius
struct CustomBarProgressStyle: ProgressViewStyle {
    @State private var width: CGFloat = 0
    
    var color: Color = .barneyPurple
    var height: Double = 12.0
    var cornerRadius: Double = 2.0
    
    func makeBody(configuration: Configuration) -> some View {
        
        let progress = configuration.fractionCompleted ?? 0.0
        
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                configuration.label
                if #available(iOS 15, *) {
                    RoundedRectangle(cornerRadius: 2.0)
                        .fill(color.opacity(0.16))
                        .frame(height: height)
                        .frame(width: geometry.size.width)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(color)
                                .frame(width: width)
                                .overlay {
                                    if let currentValueLabel = configuration.currentValueLabel {
                                        currentValueLabel
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                }
                        }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(0.16))
                            .frame(height: height)
                            .frame(width: geometry.size.width)
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color)
                                .frame(height: height)
                                .frame(width: width)
                            Spacer()
                        }
                    }
            }
            }
            .onAppear {
                withAnimation(.linear(duration: 0.6)) {
                    width = geometry.size.width * progress
                }
            }
        }
    }
}
