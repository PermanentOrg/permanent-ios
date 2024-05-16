//
//  OnboardingChartYourPathView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.05.2024.

import SwiftUI

struct OnboardingChartYourPathView: View {
    @State var presentSelectArchivesType: Bool = false
    @ObservedObject var onboardingValues: OnboardingStorageValues
    
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
            VStack {
                ScrollViewReader { scrollReader in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Chart your \npath to success")
                                .textStyle(UsualXLargeLightTextStyle())
                                .foregroundColor(.white)
                            Text("Let’s set some goals. Everyone has unique goals for preserving their legacy. We want to learn more about how we can help you achieve yours.")
                                .textStyle(UsualSmallXRegularTextStyle())
                                .foregroundColor(.blue25)
                                .lineSpacing(8.0)
                            VStack(alignment: .leading) {
                                ForEach(OnboardingPath.allCases, id: \.id) { path in
                                    Button {
                                        onboardingValues.togglePath(path: path)
                                    } label: {
                                        PathItemView(path: path, isSelected: onboardingValues.selectedPath.contains(path))
                                    }
                                }
                            }
                        }
                    }
                }
                Spacer(minLength: 160)
            }
            VStack {
                RoundButtonRightImageView(type: .noBorder, text: "Skip this step", rightImage: Image(.onboardingForward), action: skipButton)
                HStack(alignment: .center) {
                    SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.leftArrowShort), action: backButton)
                    SmallRoundButtonImageView(isDisabled: onboardingValues.textFieldText.isEmpty, text: "Next", action: nextButton)
                }
            }
            .padding(.bottom, 40)
            .sheet(isPresented: $presentSelectArchivesType, content: {
                OnboardingSelectArchiveTypeView(onboardingValues: onboardingValues)
            })
        }
    }
    
    var iPadBody: some View {
        HStack(alignment: .top, spacing: 64) {
            ScrollView(showsIndicators: false) {
                VStack {
                    HStack() {
                        Text("Create your \n\(onboardingValues.archiveType.onboardingType) archive")
                            .textStyle(UsualXXLargeLightTextStyle())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    Spacer()
                }
            }
            ZStack(alignment: .bottom) {
                ScrollViewReader { scrollReader in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 64) {
                            Text("Name your new archive. This is the legal or official name of the person, family, group, or organization the archive is about. You can edit the name later if needed.")
                                .textStyle(UsualRegularTextStyle())
                                .foregroundColor(.blue25)
                                .lineSpacing(8.0)
                            CustomBorderTextField(textFieldText: $onboardingValues.textFieldText, placeholder: "Name...")
                        }
                    }
                    .onReceive(keyboardPublisher) { keyboard in
                        if keyboard.isFirstResponder {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                                withAnimation {
                                    scrollReader.scrollTo(1, anchor: .center)
                                }
                            })
                        }
                    }
                    .onAppear {
                        UIScrollView.appearance().bounces = false
                    }
                    .onDisappear {
                        UIScrollView.appearance().bounces = true
                    }
                }
                HStack(spacing: 32) {
                    SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.backArrowOnboarding), action: backButton)
                        .frame(width: 120)
                    RoundButtonRightImageView(isDisabled: onboardingValues.textFieldText.isEmpty, text: "Create the archive", action: nextButton)
                }
                .padding(.bottom, 40)
            }
        }
    }
}
