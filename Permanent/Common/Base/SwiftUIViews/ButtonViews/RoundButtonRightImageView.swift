//
//  RoundButtonRightImageView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.03.2024.

import SwiftUI

struct RoundButtonRightImageView: View {
    enum ButtonType {
        case fillColor, noColor, noBorder
    }
    
    var type: ButtonType = .fillColor
    var isDisabled: Bool = false
    var isLoading: Bool = false
    let text: String
    var rightImage: Image = Image(.rightArrowShort)
    let action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            switch type {
            case .fillColor:
                ZStack {
                    Color(.white)
                    HStack() {
                        if Constants.Design.isPhone {
                            Text(text)
                                .textStyle(UsualSmallXMediumTextStyle())
                                .foregroundColor(.blue700)
                                .opacity(isDisabled ? 0.5 : 1)
                                .lineLimit(1)
                        } else {
                            Text(text)
                                .textStyle(UsualRegularMediumTextStyle())
                                .foregroundColor(.blue700)
                                .opacity(isDisabled ? 0.5 : 1)
                                .lineLimit(1)
                        }
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
            case .noColor:
                ZStack {
                    HStack() {
                        if Constants.Design.isPhone {
                            Text(text)
                                .textStyle(UsualSmallXMediumTextStyle())
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        } else {
                            Text(text)
                                .textStyle(UsualRegularMediumTextStyle())
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
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
            case .noBorder:
                ZStack {
                    HStack() {
                        Spacer()
                        if Constants.Design.isPhone {
                            Text(text)
                                .textStyle(UsualSmallXMediumTextStyle())
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        } else {
                            Text(text)
                                .textStyle(UsualRegularMediumTextStyle())
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(width: 24, height: 24)
                        } else {
                            rightImage
                                .frame(width: 24, height: 24, alignment: .center)
                                .accentColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
                .frame(height: 56)
                .cornerRadius(12)
                .frame(maxWidth: .infinity)
            }
        })
        .disabled(isDisabled || isLoading)
    }
}
