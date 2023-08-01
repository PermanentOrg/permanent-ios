//
//  CustomButtonStyle.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.08.2023.

import SwiftUI

struct CustomButtonStyle: ButtonStyle {
    var isLoading: Bool
    var backgroundColor: Color
    var foregroundColor: Color
    var text: String
    
    func makeBody(configuration: Self.Configuration) -> some View {
        ZStack {
            Rectangle()
                .foregroundColor(.clear)
                .frame(height: 48)
                .background(backgroundColor)
                .opacity(configuration.isPressed ? 0.6 : 1.0)
            if isLoading {
                ProgressView()
                    .frame(height: 48)
                    .foregroundColor(.clear)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text(text)
                    .multilineTextAlignment(.center)
                    .foregroundColor(foregroundColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
