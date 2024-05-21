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
                Spacer(minLength: 120)
            }
            HStack(alignment: .center) {
                SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.leftArrowShort), action: backButton)
                SmallRoundButtonImageView(isDisabled: onboardingValues.textFieldText.isEmpty, text: "Next", action: nextButton)
            }
            .padding(.bottom, 40)
            .sheet(isPresented: $presentSelectArchivesType, content: {
                OnboardingSelectArchiveTypeView(onboardingValues: onboardingValues)
            })
        }
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var iPadBody: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack {
                    HStack(alignment: .top, spacing: 0) {
                        VStack {
                            HStack() {
                                Text("Chart your \npath to success")
                                    .textStyle(UsualXXLargeLightTextStyle())
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                        }
                        .frame(width: geometry.size.width * 2 / 3)
                        
                        Text("Let’s set some goals. Everyone has unique goals for preserving their legacy. We want to learn more about how we can help you achieve yours.")
                            .textStyle(UsualRegularTextStyle())
                            .foregroundColor(.blue25)
                            .lineSpacing(8.0)
                    }
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(OnboardingPath.allCases, id: \.self) { path in
                                Button {
                                    onboardingValues.togglePath(path: path)
                                } label: {
                                    PathItemView(path: path, isSelected: onboardingValues.selectedPath.contains(path))
                                }
                                .padding(.trailing, 10)
                            }
                        }
                    }
                    Spacer(minLength: 100)
                }
                HStack(spacing: 32) {
                    Spacer(minLength: (geometry.size.width * 2 / 3) - 25)
                    SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.backArrowOnboarding), action: backButton)
                    RoundButtonRightImageView(isDisabled: onboardingValues.textFieldText.isEmpty, text: "Next", action: nextButton)
                }
                .padding(.bottom, 40)
                .padding(.trailing, 10)
            }
        }
    }
}