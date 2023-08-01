//
//  CustomButtonStyle.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.08.2023.

import SwiftUI

struct CustomButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var foregroundColor: Color
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .frame(height: 48)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(backgroundColor)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
        
    }
}
