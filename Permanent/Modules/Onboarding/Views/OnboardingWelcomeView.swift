//
//  OnboardingWelcomeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.03.2024.

import SwiftUI

struct OnboardingWelcomeView: View {
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
                Text("Hello, \(OnboardingStorageValues().fullName).\nWelcome to\nPermanent!")
                        .textStyle(UsualXLargeLightTextStyle())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                Text("\(OnboardingStorageValues().welcomeMessage)")
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
                    Text("Hello, \(OnboardingStorageValues().fullName).\nWelcome to\nPermanent!")
                        .textStyle(UsualXXLargeLightTextStyle())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
            ZStack(alignment: .bottom) {
                VStack {
                    Text("\(OnboardingStorageValues().welcomeMessage)")
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
