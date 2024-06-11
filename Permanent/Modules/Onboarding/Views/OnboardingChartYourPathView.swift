//
//  OnboardingChartYourPathView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.05.2024.

import SwiftUI

struct OnboardingChartYourPathView: View {
    @State var presentSelectArchivesType: Bool = false
    @State private var dynamicHeight: CGFloat = 0
    @ObservedObject var onboardingValues: OnboardingArchiveViewModel
    
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
                            CustomTextView(
                                preText: "Chart your \n",
                                boldText: "path",
                                postText: " to success",
                                preAndPostTextFont: TextFontStyle.style46.font,
                                boldTextFont: TextFontStyle.style47.font
                            )
                            .background(GeometryReader { geometry in
                                Color.clear.preference(key: HeightPreferenceKey.self, value: geometry.size.height)
                            })
                            .onPreferenceChange(HeightPreferenceKey.self) { value in
                                self.dynamicHeight = value
                            }
                            Text("Let’s set some goals. Everyone has unique goals for preserving their legacy. We want to learn more about how we can help you achieve yours.")
                                .textStyle(UsualSmallXRegularTextStyle())
                                .foregroundColor(.blue25)
                                .lineSpacing(8.0)
                            VStack(alignment: .leading) {
                                ForEach(OnboardingPath.allCases, id: \.id) { path in
                                    Button {
                                        onboardingValues.togglePath(path: path)
                                    } label: {
                                        OnboardingItemView(description: path.description, isSelected: onboardingValues.selectedPath.contains(path))
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
                    HStack(alignment: .top, spacing: 8) {
                        VStack {
                            HStack() {
                                CustomTextView(
                                    preText: "Chart your \n",
                                    boldText: "path",
                                    postText: " to success",
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
                        .frame(width: geometry.size.width * 2 / 3 + 2)
                        
                        Text("Let’s set some goals. Everyone has unique goals for preserving their legacy. We want to learn more about how we can help you achieve yours.")
                            .textStyle(UsualRegularTextStyle())
                            .foregroundColor(.blue25)
                            .lineSpacing(8.0)
                            .padding(.top, 10)
                    }
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(OnboardingPath.allCases, id: \.self) { path in
                                Button {
                                    onboardingValues.togglePath(path: path)
                                } label: {
                                    OnboardingItemView(description: path.description, isSelected: onboardingValues.selectedPath.contains(path))
                                }
                                .padding(.trailing, path == .collaborate || path == .createPlan ? 0 : 8)
                            }
                        }
                    }
                    .padding(.top, 15)
                    Spacer(minLength: 100)
                }
                HStack(spacing: 32) {
                    Spacer(minLength: (geometry.size.width * 2 / 3) - 25)
                    SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, text: "Back", image: Image(.backArrowOnboarding), hasSpacer: true, action: backButton)
                    RoundButtonRightImageView(text: "Next", action: nextButton)
                }
                .padding(.bottom, 40)
            }
        }
    }
}
