//
//  OnboardingWhatsImportantView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.05.2024.

import SwiftUI

struct OnboardingWhatsImportantView: View {
    @State var presentSelectArchivesType: Bool = false
    @State private var dynamicHeight: CGFloat = 0
    @ObservedObject var viewModel: OnboardingWhatsImportantViewModel
    
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
                                preText: "Tell us what’s\n",
                                boldText: "important",
                                postText: " to you"
                            )
                            Text("Finally, we’re curious -- what brought you to\nPermanent.org?")
                                .textStyle(UsualSmallXRegularTextStyle())
                                .foregroundColor(.blue25)
                                .lineSpacing(8.0)
                            VStack(alignment: .leading) {
                                ForEach(OnboardingWhatsImportant.allCases, id: \.id) { item in
                                    Button {
                                        viewModel.toggleWhatsImportant(whatsImportant: item)
                                    } label: {
                                        OnboardingItemView(description: item.description, isSelected: viewModel.containerViewModel.selectedWhatsImportant.contains(item))
                                    }
                                    .padding(.bottom, item.description.contains("Interest in digital preservation solutions") ? 4 : 0)
                                }
                            }
                        }
                    }
                    .onAppear {
                        UIScrollView.appearance().bounces = false
                    }
                    .onDisappear {
                        UIScrollView.appearance().bounces = true
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
                SmallRoundButtonImageView(text: "Next", action: {
                    viewModel.finishOnboard(_:) { response in
                        if response == .success {
                            nextButton()
                        }
                    }
                })
            }
            .padding(.bottom, 40)
            .sheet(isPresented: $presentSelectArchivesType, content: {
                OnboardingSelectArchiveTypeView(viewModel: OnboardingSelectArchiveTypeViewModel(containerViewModel: viewModel.containerViewModel))
            })
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
                                    preText: "Tell us what’s\n",
                                    boldText: "important",
                                    postText: " to you"
                                )
                                Spacer()
                            }
                        }
                        .frame(width: geometry.size.width / 2)
                        HStack {
                            Text("Finally, we’re curious...\n")
                            + Text("What brought you to Permanent.org")
                                .bold()
                            + Text("?")
                        }
                        .font(
                            .custom(
                                "Usual-Regular",
                                fixedSize: 16)
                        )
                        .foregroundColor(.blue25)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(8.0)
                        .padding(.top, 20)
                    }
                    GeometryReader { gridGeometry in
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(OnboardingWhatsImportant.allCases, id: \.self) { item in
                                    Button {
                                        viewModel.toggleWhatsImportant(whatsImportant: item)
                                    } label: {
                                        OnboardingItemView(description: item.description, isSelected: viewModel.containerViewModel.selectedWhatsImportant.contains(item), height: gridGeometry.size.height / 4)
                                    }
                                    .padding(.trailing, item == .professional ? 0 : 15)
                                }
                            }
                        }
                        .onAppear {
                            UIScrollView.appearance().bounces = false
                        }
                        .onDisappear {
                            UIScrollView.appearance().bounces = true
                        }
                        .padding(.top, 15)
                        Spacer(minLength: 100)
                    }
                }
                HStack(spacing: 32) {
                    Spacer(minLength: geometry.size.width / 2)
                    HStack(spacing: 32) {
                        SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.backArrowOnboarding), action: backButton)
                        RoundButtonRightImageView(text: "Next", action: {
                            viewModel.finishOnboard(_:) { response in
                                if response == .success {
                                    nextButton()
                                }
                            }
                        })
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    var onboardingViewModel = OnboardingWhatsImportantViewModel(containerViewModel: OnboardingContainerViewModel(username: nil, password: nil))

    return ZStack {
        Color(.primary)
        OnboardingWhatsImportantView(viewModel: onboardingViewModel) {
            
        } nextButton: {
            
        } skipButton: {
            
        }
    }
    .ignoresSafeArea()
}
