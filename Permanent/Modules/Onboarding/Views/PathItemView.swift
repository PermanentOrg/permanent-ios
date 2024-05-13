//
//  PathItemView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 10.05.2024.

import SwiftUI

struct PathItemView: View {
    var path: OnboardingPath
    var isSelected: Bool = false
    
    var body: some View {
        if isSelected {
            VStack(alignment: .leading) {
                HStack(alignment: .top, spacing: 16) {
                    Image(.checkBoxCheckedFill)
                        .renderingMode(.template)
                        .frame(width: 24, height: 24)
                        .accentColor(.white)
                    if Constants.Design.isPhone {
                        Text("\(path.description)")
                            .textStyle(UsualSmallXRegularTextStyle())
                            .foregroundColor(.white)
                            .lineSpacing(8.0)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("\(path.description)")
                            .textStyle(UsualMediumRegularTextStyle())
                            .accentColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
                .padding(.horizontal, Constants.Design.isPhone ? 24 : 32)
            }
            .frame(height: Constants.Design.isPhone ? 96 : 120)
            .background(Gradient.lightDarkPurpleGradient)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .inset(by: 0.5)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
        } else {
            VStack(alignment: .leading) {
                HStack(alignment: .top, spacing: 16) {
                    Image(.checkBoxEmpty)
                        .renderingMode(.template)
                        .frame(width: 24, height: 24)
                        .accentColor(.white)
                    if Constants.Design.isPhone {
                        Text("\(path.description)")
                            .textStyle(UsualSmallXRegularTextStyle())
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .lineSpacing(8.0)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("\(path.description)")
                            .textStyle(UsualMediumRegularTextStyle())
                            .accentColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
                .padding(.horizontal, Constants.Design.isPhone ? 24 : 32)
            }
            .frame(height: Constants.Design.isPhone ? 96 : 120)
            .frame(maxWidth: .infinity)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .inset(by: 0.5)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
        }
    }
}
