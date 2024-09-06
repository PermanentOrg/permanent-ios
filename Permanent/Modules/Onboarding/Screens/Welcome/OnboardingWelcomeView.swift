//
//  OnboardingWelcomeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.03.2024.

import SwiftUI
import UIKit

struct OnboardingWelcomeView: View {
    @ObservedObject var viewModel: OnboardingInvitedWelcomeViewModel
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
                    boldText: "\(viewModel.containerViewModel.fullName)",
                    postText: ".\nWelcome to\nPermanent!"
                )
                Text("We’re so glad you’re here!\n\nAt Permanent, it is our mission to provide a safe and secure place to store, preserve, and share the digital legacy of all people, whether that's for you or for your friends, family, interests or organizations.\n\nWe know that starting this journey can sometimes be overwhelming, but don’t worry. We’re here to help you every step of the way.")
                    .textStyle(UsualSmallXRegularTextStyle())
                    .foregroundColor(.blue25)
                    .lineSpacing(8.0)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            
            RoundButtonRightImageView(text: "Get started", action: {
                buttonAction()
                viewModel.containerViewModel.creatingNewArchive = true
            })
            .padding(.bottom, 40)
        }
    }
    
    var iPadBody: some View {
        HStack(alignment: .top, spacing: 64) {
            VStack() {
                HStack() {
                    OnboardingTitleTextView(
                        preText: "Hello, ",
                        boldText: "\(viewModel.containerViewModel.fullName)",
                        postText: ".\nWelcome to\nPermanent!"
                    )
                    Spacer()
                }
            }
            ZStack(alignment: .bottom) {
                VStack {
                    Text("We’re so glad you’re here!\n\nAt Permanent, it is our mission to provide a safe and secure place to store, preserve, and share the digital legacy of all people, whether that's for you or for your friends, family, interests or organizations.\n\nWe know that starting this journey can sometimes be overwhelming, but don’t worry. We’re here to help you every step of the way.")
                        .textStyle(UsualRegularTextStyle())
                        .foregroundColor(.blue25)
                        .lineSpacing(8.0)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.top, 10)
                HStack {
                    Spacer()
                    RoundButtonRightImageView(text: "Get started", action: {
                        buttonAction()
                        viewModel.containerViewModel.creatingNewArchive = true
                    })
                    .frame(width: 243)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

#Preview {
    var viewModel = OnboardingInvitedWelcomeViewModel(containerViewModel: OnboardingContainerViewModel(username: "", password: ""))
    viewModel.containerViewModel.fullName = "really long user name"

    return ZStack {
        Color(.primary)
        OnboardingWelcomeView(viewModel: viewModel, buttonAction: {
            
        })
    }
    .ignoresSafeArea()
}
