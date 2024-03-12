//
//  RoundButtonRightImageView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.03.2024.

import SwiftUI

struct RoundButtonRightImageView: View {
    enum ButtonType {
        case fillColor, noColor
    }
    
    var type: ButtonType = .fillColor
    var isDisabled: Bool = false
    var isLoading: Bool = false
    let text: String
    let rightImage: Image = Image(.rightArrowShort)
    let action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            if type == .fillColor {
                ZStack {
                    Color(.white)
                    HStack() {
                        Text(text)
                            .textStyle(UsualSmallXMediumTextStyle())
                            .foregroundColor(.blue700)
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue700))
                                .frame(width: 24, height: 24)
                        } else {
                            rightImage
                                .frame(width: 24, height: 24, alignment: .center)
                                .accentColor(.blue700)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .frame(height: 56)
                .cornerRadius(12)
                .frame(maxWidth: .infinity)
            }
            if type == .noColor {
                ZStack {
                    HStack() {
                        Text(text)
                            .textStyle(UsualSmallXMediumTextStyle())
                            .foregroundColor(.white)
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(width: 24, height: 24)
                        } else {
                            rightImage
                                .frame(width: 24, height: 24, alignment: .center)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .frame(height: 56)
                .cornerRadius(12)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.5)
                        .stroke(.white.opacity(0.32), lineWidth: 1)
                    
                )
            }
        })
        .disabled(isDisabled || isLoading)
    }
}
