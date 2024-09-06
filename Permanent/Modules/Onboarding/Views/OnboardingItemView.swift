//
//  PathItemView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 10.05.2024.

import SwiftUI

struct OnboardingItemView: View {
    var description: String
    var isSelected: Bool = false
    var height: CGFloat = Constants.Design.isPhone ? 96 : 120
    
    var body: some View {
        if isSelected {
            if Constants.Design.isPhone {
                VStack(alignment: .leading) {
                    HStack(alignment: .top, spacing: 16) {
                        Image(.checkBoxCheckedFill)
                            .renderingMode(.template)
                            .frame(width: 24, height: 24)
                            .accentColor(.white)
                        Text("\(description)")
                            .textStyle(UsualSmallXRegularTextStyle())
                            .foregroundColor(.white)
                            .lineSpacing(8.0)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, Constants.Design.isPhone ? 24 : 32)
                }
                .frame(height: height)
                .background(Gradient.lightDarkPurpleGradient)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.5)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                )
            } else {
                VStack(alignment: .leading) {
                    HStack(alignment: .center, spacing: 0) {
                        Image(.checkBoxCheckedFill)
                            .renderingMode(.template)
                            .frame(width: 30, height: 30)
                            .accentColor(.white)
                            .foregroundColor(.white)
                            .padding(.top, -5)
                        Text("\(description)")
                            .textStyle(UsualSmallXRegularTextStyle())
                            .accentColor(.white)
                            .foregroundColor(.white)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .padding(.leading, 10)
                            .minimumScaleFactor(0.85)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, Constants.Design.isPhone ? 24 : 16)
                }
                .frame(height: height)
                .background(Gradient.lightDarkPurpleGradient)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.5)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                )
            }
        } else {
            if Constants.Design.isPhone {
                VStack(alignment: .leading) {
                    HStack(alignment: .top, spacing: 16) {
                        Image(.checkBoxEmpty)
                            .renderingMode(.template)
                            .frame(width: 24, height: 24)
                            .accentColor(.white)
                        Text("\(description)")
                            .textStyle(UsualSmallXRegularTextStyle())
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .lineSpacing(8.0)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, Constants.Design.isPhone ? 24 : 32)
                }
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.07, green: 0.11, blue: 0.29))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.5)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                )
            } else {
                VStack(alignment: .leading) {
                    HStack(alignment: .center, spacing: 0) {
                        Image(.checkBoxEmpty)
                            .renderingMode(.template)
                            .frame(width: 30, height: 30)
                            .accentColor(.white)
                            .foregroundColor(.white)
                            .padding(.top, -5)
                        Text("\(description)")
                            .textStyle(UsualSmallXRegularTextStyle())
                            .accentColor(.white)
                            .foregroundColor(.white)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .padding(.leading, 10)
                            .minimumScaleFactor(0.85)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, Constants.Design.isPhone ? 24 : 16)
                }
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .background(Color(.blue900))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.5)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                )
            }
        }
    }
}

#Preview {
    return ZStack {
        Color(.black)
        VStack(spacing: 32) {
            OnboardingItemView(description: "Create a plan for passing on my digital materials", isSelected: true)
                .frame(width: 200)
            OnboardingItemView(description: "Create a plan for passing on my digital materials", isSelected: false)
                .frame(width: 200)
        }
    }
    .ignoresSafeArea()
}
