//
//  OnboardingWelcomeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.03.2024.

import SwiftUI

struct OnboardingWelcomeView: View {
    var fullName: String = ""
    var buttonAction: (() -> Void)
    let welcomeMessage: String = "We’re so glad you’re here!\n\nAt Permanent, it is our mission to provide a safe and secure place to store, preserve, and share the digital legacy of all people, whether that's for you or for your friends, family, interests or organizations.\n\nWe know that starting this journey can sometimes be overwhelming, but don’t worry. We’re here to help you every step of the way."
    
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
                VStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        Text("Hello, ")
                            .textStyle(UsualXLargeLightTextStyle())
                            .foregroundColor(.white)
                        Text("\(fullName)")
                            .textStyle(UsualXLargeBoldTextStyle())
                            .foregroundColor(.white)
                        Text("!")
                            .textStyle(UsualXLargeLightTextStyle())
                            .foregroundColor(.white)
                        Spacer()
                    }
                    Text("Welcome to")
                        .textStyle(UsualXLargeLightTextStyle())
                        .foregroundColor(.white)
                    Text("Permanent!")
                        .textStyle(UsualXLargeLightTextStyle())
                        .foregroundColor(.white)
                }
                Text("\(welcomeMessage)")
                    .textStyle(UsualSmallXRegularTextStyle())
                    .foregroundColor(.blue25)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .lineSpacing(8.0)
            }
            RoundButtonRightImageView(text: "Get started", action: buttonAction)
        }
    }
    var iPadBody: some View {
        HStack(alignment: .top, spacing: 64) {
            VStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Text("Hello, ")
                        .textStyle(UsualXXLargeLightTextStyle())
                        .foregroundColor(.white)
                    Text("\(fullName)")
                        .textStyle(UsualXXLargeBoldTextStyle())
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(".")
                        .textStyle(UsualXXLargeLightTextStyle())
                        .foregroundColor(.white)
                    Spacer()
                }
                Text("Welcome")
                    .textStyle(UsualXXLargeLightTextStyle())
                    .foregroundColor(.white)
                Text("to Permanent!")
                    .textStyle(UsualXXLargeLightTextStyle())
                    .foregroundColor(.white)
            }
            ZStack(alignment: .bottom) {
                VStack {
                    Text("\(welcomeMessage)")
                        .textStyle(UsualRegularTextStyle())
                        .foregroundColor(.blue25)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .lineSpacing(8.0)
                    Spacer()
                }
                HStack {
                    Spacer()
                    RoundButtonRightImageView(text: "Get started", action: buttonAction)
                        .frame(width: 170)
                }
            }
        }
    }
}
