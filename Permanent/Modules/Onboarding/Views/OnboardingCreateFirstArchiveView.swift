//
//  OnboardingCreateFirstArchiveView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.03.2024.

import SwiftUI

struct OnboardingCreateFirstArchiveView: View {
    @State var archiveType: String = "Personal"
    
    var backButton: (() -> Void)
    var nextButton: (() -> Void)
    
    var body: some View {
        if Constants.Design.isPhone {
            iPhoneBody
        } else {
            iPadBody
        }
    }
    
    var iPhoneBody: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Create your first\nArchive.")
                    .textStyle(UsualXLargeLightTextStyle())
                    .foregroundColor(.white)
                Text("What do you plan to capture and preserve with your first archive?")
                    .textStyle(UsualSmallXRegularTextStyle())
                    .foregroundColor(.blue25)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .lineSpacing(8.0)
                Spacer()
            }
            HStack {
                SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.leftArrowShort), action: backButton)
                SmallRoundButtonImageView(text: "Next", action: nextButton)
                
            }
        }
    }
    var iPadBody: some View {
        HStack(alignment: .top, spacing: 64) {
            VStack(alignment: .leading) {
                Text("Create your first\nArchive.")
                    .textStyle(UsualXXLargeLightTextStyle())
                    .foregroundColor(.white)
                Spacer()
            }
            ZStack(alignment: .bottom) {
                VStack {
                    Text("With my first archive, I plan to capture and preserve material about…")
                        .textStyle(UsualRegularTextStyle())
                        .foregroundColor(.blue25)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .lineSpacing(8.0)
                    Spacer()
                }
                .padding(.top, 10)
                HStack(spacing: 16) {
                    SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.backArrowOnboarding), action: backButton)
                        .frame(width: 120)
                    RoundButtonRightImageView(text: "Let’s create a \(archiveType) archive", action: nextButton)
                }
            }
        }
    }
}
