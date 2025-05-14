//
//  RoundButtonView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.12.2023.

import SwiftUI

struct RoundButtonView: View {
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
                            .textStyle(RegularSemiBoldTextStyle())
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

struct RoundButtonUsualView: View {
    var isDisabled: Bool
    var isLoading: Bool
    let text: String
    let action: () -> Void
    var textSize: CGFloat = 14
    
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
                            .font(.custom("Usual-Regular", size: textSize))
                            .fontWeight(.medium)
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

struct GreyRoundButtonUsualView: View {
    var isDisabled: Bool
    var isLoading: Bool
    let text: String
    let action: () -> Void
    var textSize: CGFloat = 14
    
    var body: some View {
        Button(action: action, label: {
            ZStack {
                Color(isDisabled ? .blue200 : .blue25)
                HStack() {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue900))
                            .fontWeight(.medium)
                            .frame(width: 10, height: 10)
                    } else {
                        Text(text)
                            .font(.custom("Usual-Regular", size: textSize))
                            .foregroundColor(.blue900)
                    }
                }
            }
            .frame(height: 56)
            .cornerRadius(12)
        })
        .disabled(isDisabled || isLoading)
    }
}
