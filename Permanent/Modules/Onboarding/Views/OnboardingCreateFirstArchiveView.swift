//
//  OnboardingCreateFirstArchiveView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.03.2024.

import SwiftUI

struct OnboardingCreateFirstArchiveView: View {
    var backButton: (() -> Void)
    var nextButton: (() -> Void)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                VStack(alignment: .leading) {
                    Text("Create your first ")
                        .textStyle(UsualXLargeLightTextStyle())
                        .foregroundColor(.white)
                    HStack {
                        Text("Archive")
                            .textStyle(UsualXLargeBoldTextStyle())
                            .foregroundColor(.white)
                        Text("!")
                            .textStyle(UsualXLargeLightTextStyle())
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                Text("What do you plan to capture and preserve with your first archive?")
                    .textStyle(UsualSmallXRegularTextStyle())
                    .foregroundColor(.blue25)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .lineSpacing(8.0)
                
            }
            HStack {
                SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.leftArrowShort), action: backButton)
                SmallRoundButtonImageView(text: "Next", action: nextButton)
                
            }
        }
    }
}
