//
//  OnboardingCreateFirstArchiveView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.03.2024.

import SwiftUI

struct OnboardingCreateFirstArchiveView: View {
    @State var presentSelectArchivesType: Bool = false
    @State private var dynamicHeight: CGFloat = 0
    @ObservedObject var viewModel: OnboardingCreateFirstArchiveViewModel
    
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
                OnboardingTitleTextView(
                    preText: "Create your first\n",
                    boldText: "Archive",
                    postText: " "
                )
                Text("What do you plan to capture and preserve with your first archive?")
                    .textStyle(UsualSmallXRegularTextStyle())
                    .foregroundColor(.blue25)
                    .lineSpacing(8.0)
                    .multilineTextAlignment(.leading)
                
                GradientArchiveButtonView(action: {
                    presentSelectArchivesType = true
                }, archiveType: $viewModel.containerViewModel.archiveType)
                Spacer()
            }
            HStack(alignment: .center) {
                SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.leftArrowShort), action: backButton)
                SmallRoundButtonImageView(text: "Next", action: nextButton)
            }
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $presentSelectArchivesType, content: {
            OnboardingSelectArchiveTypeView(viewModel: OnboardingSelectArchiveTypeViewModel(containerViewModel: viewModel.containerViewModel))
        })
    }
    
    var iPadBody: some View {
        HStack(alignment: .top, spacing: 64) {
            VStack {
                HStack() {
                    OnboardingTitleTextView(
                        preText: "Create your\nfirst ",
                        boldText: "Archive",
                        postText: ""
                    )
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
                        presentSelectArchivesType = true
                    }, archiveType: $viewModel.containerViewModel.archiveType)
                    Spacer()
                }
                HStack(spacing: 32) {
                    SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.backArrowOnboarding), action: backButton)
                        //.frame(width: 120)
                    RoundButtonRightImageView(text: "Next", action: nextButton)
                }
                .padding(.bottom, 40)
            }
            .padding(.top, 10)
        }
        .sheet(isPresented: $presentSelectArchivesType, content: {
            OnboardingSelectArchiveTypeView(viewModel: OnboardingSelectArchiveTypeViewModel(containerViewModel: viewModel.containerViewModel))
        })
    }
}

#Preview {
    var onboardingViewModel = OnboardingCreateFirstArchiveViewModel(containerViewModel: OnboardingContainerViewModel(username: "", password: ""))
    
    return ZStack {
        Color(.primary)
        OnboardingCreateFirstArchiveView(viewModel: onboardingViewModel) {
            
        } nextButton: {
            
        }
    }
    .ignoresSafeArea()
}
