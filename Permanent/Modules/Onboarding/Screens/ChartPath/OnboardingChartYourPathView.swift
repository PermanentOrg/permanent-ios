//
//  OnboardingChartYourPathView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.05.2024.

import SwiftUI

struct OnboardingChartYourPathView: View {
    @State private var dynamicHeight: CGFloat = 0
    @ObservedObject var viewModel: OnboardingChartYourPathViewModel
    
    var backButton: (() -> Void)
    var nextButton: (() -> Void)
    var skipButton: (() -> Void)
    @State var isKeyboardPresented = false
    @State var textFieldText: String = ""
    
    var body: some View {
        if Constants.Design.isPhone {
            iPhoneBody
        } else {
            iPadBody
        }
    }
    
    var iPhoneBody: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ScrollViewReader { scrollReader in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            OnboardingTitleTextView(
                                preText: "Chart your \n",
                                boldText: "path",
                                postText: " to success"
                            )
                            Text("Let’s set some goals. Everyone has unique goals for preserving their legacy. We want to learn more about how we can help you achieve yours.")
                                .textStyle(UsualSmallXRegularTextStyle())
                                .foregroundColor(.blue25)
                                .lineSpacing(8.0)
                            VStack(alignment: .leading) {
                                ForEach(OnboardingPath.allCases, id: \.id) { path in
                                    Button {
                                        viewModel.togglePath(path: path)
                                    } label: {
                                        OnboardingItemView(description: path.description, isSelected: viewModel.containerViewModel.selectedPath.contains(path))
                                    }
                                    .padding(.bottom, path.description.contains("Something else") ? 4 : 0)
                                }
                            }
                        }
                    }
                }
                Color(.white)
                    .opacity(0.16)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, -40)
                Spacer(minLength: 130)
            }
            HStack(alignment: .center) {
                SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.leftArrowShort), action: backButton)
                SmallRoundButtonImageView(text: "Next", action: nextButton)
            }
            .padding(.bottom, 40)
        }
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var iPadBody: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack(spacing: 64) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack {
                            HStack() {
                                OnboardingTitleTextView(
                                    preText: "Chart your \n",
                                    boldText: "path",
                                    postText: " to success"
                                )
                                Spacer()
                            }
                        }
                        .frame(width: geometry.size.width / 2)
                        
                        Text("Let’s set some goals. Everyone has unique goals for preserving their legacy. We want to learn more about how we can help you achieve yours. \n\nMy goal is to...")
                            .textStyle(UsualRegularTextStyle())
                            .foregroundColor(.blue25)
                            .lineSpacing(8.0)
                            .padding(.top, 20)
                    }
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(OnboardingPath.allCases, id: \.self) { path in
                                Button {
                                    viewModel.togglePath(path: path)
                                } label: {
                                    OnboardingItemView(description: path.description, isSelected: viewModel.containerViewModel.selectedPath.contains(path))
                                }
                                .padding(.trailing, path == .createPublicArchive || path == .somethingElse ? 0 : 15)
                            }
                        }
                    }
                    .padding(.top, 15)
                    Spacer(minLength: 100)
                }
                HStack(spacing: 0) {
                    Spacer(minLength: geometry.size.width / 2)
                    HStack(spacing: 32) {
                        SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.backArrowOnboarding), action: backButton)
                        RoundButtonRightImageView(text: "Next", action: nextButton)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    var onboardingViewModel = OnboardingChartYourPathViewModel(containerViewModel: OnboardingContainerViewModel(username: "none", password: "none"))
    
    return ZStack {
        Color(.primary)
        OnboardingChartYourPathView(viewModel: onboardingViewModel) {
            
        } nextButton: {
            
        } skipButton: {
            
        }
    }
    .ignoresSafeArea()
}
