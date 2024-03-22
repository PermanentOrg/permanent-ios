//
//  OnboardingCreateFirstArchiveView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.03.2024.

import SwiftUI

struct OnboardingCreateFirstArchiveView: View {
    @State var archiveType: ArchiveType = .person
    @State var presentArchivesList: Bool = false
    
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
                Text("Create your first\narchive.")
                    .textStyle(UsualXLargeLightTextStyle())
                    .foregroundColor(.white)
                Text("What do you plan to capture and preserve with your first archive?")
                    .textStyle(UsualSmallXRegularTextStyle())
                    .foregroundColor(.blue25)
                    .lineSpacing(8.0)
                GradientArchiveButtonView(action: {
                    presentArchivesList = true
                }, archiveType: archiveType)
                Spacer()
            }
            HStack(alignment: .center) {
                SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.leftArrowShort), action: backButton)
                SmallRoundButtonImageView(text: "Next", action: nextButton)
                
            }
        }
    }
    
    var iPadBody: some View {
        HStack(alignment: .top, spacing: 64) {
            VStack {
                HStack() {
                    Text("Create your\nfirst archive.")
                        .textStyle(UsualXXLargeLightTextStyle())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                Spacer()
            }
            ZStack(alignment: .bottom) {
                VStack(spacing: 32) {
                    HStack() {
                        Text("With my first archive, I plan to capture and preserve material about…")
                            .textStyle(UsualRegularTextStyle())
                            .foregroundColor(.blue25)
                            .lineSpacing(8.0)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    GradientArchiveButtonView(action: {
                        presentArchivesList = true
                    }, archiveType: archiveType)
                    Spacer()
                }
                HStack(spacing: 32) {
                    SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.backArrowOnboarding), action: backButton)
                        .frame(width: 120)
                    RoundButtonRightImageView(text: "Let’s create a \(archiveType) archive", action: nextButton)
                }
            }
            .padding(.top, 10)
        }
    }
}
