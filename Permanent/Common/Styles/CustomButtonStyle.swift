//
//  CustomButtonStyle.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.08.2023.
//

import SwiftUI

struct CustomButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var foregroundColor: Color
    var height: CGFloat = 48
    var cornerRadius: CGFloat = 0
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .frame(height: height)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}
