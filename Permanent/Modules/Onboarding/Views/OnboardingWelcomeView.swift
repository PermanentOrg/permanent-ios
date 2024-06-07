//
//  OnboardingWelcomeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.03.2024.

import SwiftUI
import UIKit

struct OnboardingWelcomeView: View {
    var onboardingStorageValues: OnboardingStorageValues
    @State private var dynamicHeight: CGFloat = 0
    var buttonAction: (() -> Void)
    
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
                CustomTextView(
                    preText: "Hello, ",
                    boldText: "\(onboardingStorageValues.fullName)",
                    postText: ".\nWelcome to\nPermanent!",
                    preAndPostTextFont: TextFontStyle.style46.font,
                    boldTextFont: TextFontStyle.style47.font
                )
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: HeightPreferenceKey.self, value: geometry.size.height)
                })
                .onPreferenceChange(HeightPreferenceKey.self) { value in
                    self.dynamicHeight = value
                }
                Text("\(onboardingStorageValues.welcomeMessage)")
                    .textStyle(UsualSmallXRegularTextStyle())
                    .foregroundColor(.blue25)
                    .lineSpacing(8.0)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            
            RoundButtonRightImageView(text: "Get started", action: buttonAction)
                .padding(.bottom, 40)
        }
    }
    
    var iPadBody: some View {
        HStack(alignment: .top, spacing: 64) {
            VStack() {
                HStack() {
                    CustomTextView(
                        preText: "Hello, ",
                        boldText: "\(onboardingStorageValues.fullName)",
                        postText: ".\nWelcome to\nPermanent!",
                        preAndPostTextFont: TextFontStyle.style48.font,
                        boldTextFont: TextFontStyle.style49.font
                    )
                    .background(GeometryReader { geometry in
                        Color.clear.preference(key: HeightPreferenceKey.self, value: geometry.size.height)
                    })
                    .onPreferenceChange(HeightPreferenceKey.self) { value in
                        self.dynamicHeight = value
                    }
                    Spacer()
                }
            }
            ZStack(alignment: .bottom) {
                VStack {
                    Text("\(onboardingStorageValues.welcomeMessage)")
                        .textStyle(UsualRegularTextStyle())
                        .foregroundColor(.blue25)
                        .lineSpacing(8.0)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.top, 10)
                HStack {
                    Spacer()
                    RoundButtonRightImageView(text: "Get started", action: buttonAction)
                        .frame(width: 170)
                        .padding(.bottom, 40)
                }
            }
        }
    }
}
