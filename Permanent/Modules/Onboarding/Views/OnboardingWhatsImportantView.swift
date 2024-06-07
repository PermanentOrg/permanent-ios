//
//  OnboardingWhatsImportantView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 27.05.2024.

import SwiftUI

struct OnboardingWhatsImportantView: View {
    @State var presentSelectArchivesType: Bool = false
    @State private var dynamicHeight: CGFloat = 0
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
            VStack(spacing: 0) {
                ScrollViewReader { scrollReader in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            CustomTextView(
                                preText: "Tell us what’s\n",
                                boldText: "important",
                                postText: " to you",
                                preAndPostTextFont: TextFontStyle.style46.font,
                                boldTextFont: TextFontStyle.style47.font
                            )
                            .background(GeometryReader { geometry in
                                Color.clear.preference(key: HeightPreferenceKey.self, value: geometry.size.height)
                            })
                            .onPreferenceChange(HeightPreferenceKey.self) { value in
                                self.dynamicHeight = value
                            }
                            Text("Finally, we’re curious -- what brought you to\nPermanent.org?")
                                .textStyle(UsualSmallXRegularTextStyle())
                                .foregroundColor(.blue25)
                                .lineSpacing(8.0)
                            VStack(alignment: .leading) {
                                ForEach(OnboardingWhatsImportant.allCases, id: \.id) { item in
                                    Button {
                                        onboardingValues.toggleWhatsImportant(whatsImportant: item)
                                    } label: {
                                        OnboardingItemView(description: item.description, isSelected: onboardingValues.selectedWhatsImportant.contains(item))
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
                SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft,isDisabled: onboardingValues.isLoading, text: "Back", image: Image(.leftArrowShort), action: backButton)
                SmallRoundButtonImageView(isLoading: onboardingValues.isLoading, text: "Next", action: nextButton)
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
                                CustomTextView(
                                    preText: "Tell us what’s\n",
                                    boldText: "important",
                                    postText: " to you",
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
                        
                        Text("Finally, we’re curious -- what brought you to\nPermanent.org?")
                            .textStyle(UsualRegularTextStyle())
                            .foregroundColor(.blue25)
                            .lineSpacing(8.0)
                            .padding(.top, 10)
                    }
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(OnboardingWhatsImportant.allCases, id: \.self) { item in
                                Button {
                                    onboardingValues.toggleWhatsImportant(whatsImportant: item)
                                } label: {
                                    OnboardingItemView(description: item.description, isSelected: onboardingValues.selectedWhatsImportant.contains(item))
                                }
                                .padding(.trailing, item == .preserving || item == .interest ? 0 : 8)
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
                HStack(spacing: 32) {
                    Spacer(minLength: (geometry.size.width * 2 / 3) - 25)
                    SmallRoundButtonImageView(type: .noColor, imagePlace: .onLeft, isDisabled: onboardingValues.isLoading, text: "Back", image: Image(.backArrowOnboarding), hasSpacer: true, action: backButton)
                    RoundButtonRightImageView(isLoading: onboardingValues.isLoading, text: "Next", action: nextButton)
                }
                .padding(.bottom, 40)
            }
        }
    }
}
