//
//  GradientArchiveButtonView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 19.03.2024.

import SwiftUI

struct GradientArchiveButtonView: View {
    var action: (() -> Void)
    @Binding var archiveType: ArchiveType
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 24) {
                archiveType.onboardingDescriptionIcon
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                HStack() {
                    if Constants.Design.isPhone {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(archiveType.onboardingType)")
                                .textStyle(UsualSmallXMediumTextStyle())
                                .foregroundColor(.white)
                            Text("\(archiveType.onboardingDescription)")
                                .textStyle(UsualSmallXXXRegularTextStyle())
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .lineSpacing(4.0)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("\(archiveType.onboardingType)")
                                .textStyle(UsualMediumTextStyle())
                                .foregroundColor(.white)
                            Text("\(archiveType.onboardingDescription)")
                                .textStyle(UsualMediumRegularTextStyle())
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.white.opacity(0.75))
                                .lineSpacing(4.0)
                        }
                    }
                    Spacer()
                }
                Image(.onboardingArrowDown)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
            }
            .padding(Constants.Design.isPhone ? 24 : 32)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Constants.Design.isPhone ? 112 : 168)
        .background(Gradient.purpleYellowGradient2)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        )
    }
}
