//
//  SmallRoundButtonImageView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.03.2024.

import SwiftUI

struct SmallRoundButtonImageView: View {
    
    enum ButtonType {
        case fillColor, noColor
    }
    enum ImagePlace {
        case onLeft, onRight, none
    }
    
    var type: ButtonType = .fillColor
    var imagePlace: ImagePlace = .onRight
    var isDisabled: Bool = false
    var isLoading: Bool = false
    let text: String
    var image: Image = Image(.rightArrowShort)
    var hasSpacer: Bool = false
    let action: () -> Void
    var ignoreDeviceType: Bool = false
    var isPhone: Bool = true
    
    var body: some View {
        Button(action: action, label: {
            VStack(alignment: .center) {
                if type == .fillColor {
                    ZStack {
                        Color(.white)
                        HStack(spacing: 10) {
                            if imagePlace == .onLeft {
                                image
                                    .frame(width: 24, height: 24, alignment: .center)
                                    .accentColor(.blue700)
                            }
                            if Constants.Design.isPhone || (ignoreDeviceType && isPhone){
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
                            if imagePlace == .onRight {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue700))
                                        .frame(width: 24, height: 24)
                                } else {
                                    image
                                        .frame(width: 24, height: 24, alignment: .center)
                                        .accentColor(.blue700)
                                }
                            }
                        }
                    }
                    .frame(height: 56)
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity)
                }
                if type == .noColor {
                    ZStack {
                        HStack(spacing: 10) {
                            if imagePlace == .onLeft {
                                image
                                    .frame(width: 24, height: 24, alignment: .center)
                                    .accentColor(.white)
                                if hasSpacer {
                                    Spacer()
                                }
                            }
                            if Constants.Design.isPhone || (ignoreDeviceType && isPhone){
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
                            if imagePlace == .onRight {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(width: 24, height: 24)
                                } else {
                                    image
                                        .frame(width: 24, height: 24, alignment: .center)
                                        .accentColor(.white)
                                }
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
            }
        })
        .disabled(isDisabled || isLoading)
    }
}
