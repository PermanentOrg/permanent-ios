//
//  OnboardingWelcomeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.03.2024.

import SwiftUI
import UIKit

struct OnboardingWelcomeView: View {
    var onboardingStorageValues: OnboardingArchiveViewModel
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
                OnboardingTitleTextView(
                    preText: "Hello, ",
                    boldText: "\(onboardingStorageValues.fullName)",
                    postText: ".\nWelcome to\nPermanent!"
                )
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
                    OnboardingTitleTextView(
                        preText: "Hello, ",
                        boldText: "\(onboardingStorageValues.fullName)",
                        postText: ".\nWelcome to\nPermanent!"
                    )
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
                        .frame(width: 243)
                        .padding(.bottom, 40)
                }
            }
        }
    }
}

#Preview {
    var onboardingViewModel = OnboardingArchiveViewModel(username: "none", password: "none")
    onboardingViewModel.fullName = "long archive name name name"
    
    return ZStack {
        Color(.primary)
        OnboardingWelcomeView(onboardingStorageValues: onboardingViewModel) {
            
        }
    }
    .ignoresSafeArea()
}
