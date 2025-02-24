//
//  RoundButtonUsualBlue50View.swift
//  Permanent
//
//  Created by Lucian Cerbu on 19.02.2025.
import SwiftUI

struct RoundButtonUsualBlue50View: View {
    var isDisabled: Bool
    var isLoading: Bool
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            ZStack {
                Color(isDisabled ? .blue25 : .blue25)
                HStack() {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue900))
                            .frame(width: 10, height: 10)
                    } else {
                        Text(text)
                            .textStyle(UsualSmallXMediumTextStyle())
                            .foregroundColor(.blue900)
                    }
                }
            }
            .frame(height: 56)
            .cornerRadius(12)
        })
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1)
    }
}
