//
//  RoundButtonUsualFontView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.11.2024.

import SwiftUI

struct RoundButtonUsualFontView: View {
    var isDisabled: Bool
    var isLoading: Bool
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            ZStack {
                Color(isDisabled ? .blue200 : .blue900)
                HStack() {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(width: 10, height: 10)
                    } else {
                        Text(text)
                            .textStyle(UsualSmallXMediumTextStyle())
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(height: 56)
            .cornerRadius(12)
        })
        .disabled(isDisabled || isLoading)
    }
}
