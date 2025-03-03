//
//  SimpleTagView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.12.2024.

import SwiftUI

struct SimpleTagView: View {
    let text: String
    let textColor: Color
    let backgroundColor: Color
    
    init(
        text: String,
        textColor: Color = Color(red: 0.07, green: 0.11, blue: 0.29),
        backgroundColor: Color = Color(red: 0.96, green: 0.96, blue: 0.99)
    ) {
        self.text = text
        self.textColor = textColor
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        if #available(iOS 16.0, *) {
            Text(text)
                .textStyle(UsualSmallXXXXXMediumTextStyle())
                .foregroundColor(textColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(backgroundColor)
                .cornerRadius(6)
                .kerning(1.6)
        } else {
            Text(text)
                .textStyle(UsualSmallXXXXXMediumTextStyle())
                .foregroundColor(textColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(backgroundColor)
                .cornerRadius(6)
        }
    }
} 
