//
//  OnboardingCongratulationsView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.06.2024.

import SwiftUI

struct OnboardingCongratulationsView: View {
    @ObservedObject var onboardingValues: OnboardingArchiveViewModel
    
    var backButton: (() -> Void)
    var nextButton: (() -> Void)
    
    @State private var contentSize: CGSize = .zero
    
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
                Text("Congratulations!")
                    .textStyle(UsualXLargeLightTextStyle())
                    .foregroundColor(.white)
                    .lineSpacing(8.0)
                Text("Get started by uploading your first files, or learn more about your new archive by viewing our help articles through the ‘?’ button in the lower right-hand corner.")
                    .textStyle(UsualSmallXRegularTextStyle())
                    .foregroundColor(.blue25)
                    .lineSpacing(8.0)
                ScrollViewReader { scrollReader in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(onboardingValues.pendingArchives) {archive in
                                ArchiveDetailsView(pendingArchive: archive)
                            }
                        }
                    }
                    .onAppear {
                        UIScrollView.appearance().bounces = false
                    }
                    .onDisappear {
                        UIScrollView.appearance().bounces = true
                    }
                    Spacer()
                }
                
                
            }
            HStack(alignment: .center) {
                SmallRoundButtonImageView(isDisabled: onboardingValues.archiveName.isEmpty, text: "Done", image: Image(.onboardingCheckmark),  action: nextButton)
            }
            .padding(.bottom, 40)
        }
    }
    
    var iPadBody: some View {
        HStack(alignment: .top, spacing: 64) {
            ScrollView(showsIndicators: false) {
                VStack {
                    HStack() {
                        Text("Congratulations!")
                            .textStyle(UsualXXLargeLightTextStyle())
                            .foregroundColor(.white)
                            .lineSpacing(8.0)
                        Spacer()
                    }
                    Spacer()
                }
            }
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 32) {
                        if !onboardingValues.pendingArchives.isEmpty {
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 32) {
                                    ForEach(onboardingValues.pendingArchives) {archive in
                                        ArchiveDetailsView(pendingArchive: archive)
                                    }
                                }
                                .overlay(
                                    GeometryReader { geo in
                                        Color.clear.onAppear {
                                            contentSize = geo.size
                                        }
                                    }
                                )
                            }
                            .onAppear {
                                UIScrollView.appearance().bounces = false
                            }
                            .onDisappear {
                                UIScrollView.appearance().bounces = true
                            }
                            .frame(maxHeight: contentSize.height)
                            
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
                                .background(Color(.white))
                                .opacity(0.1)
                        }
                        
                        HStack {
                            Text("Get started by uploading your first files, or learn more about your new archive by ")
                            + Text("[viewing our help articles here.](https://permanent.zohodesk.com/portal/en/kb/permanent-legacy-foundation)")
                                .underline()
                        }
                        .font(
                            .custom(
                                "Usual-Regular",
                                fixedSize: 16)
                        )
                        .foregroundColor(.blue25)
                        .accentColor(.blue25)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(8.0)
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                    HStack(spacing: 32) {
                        Spacer(minLength: geometry.size.width / 2)
                        RoundButtonRightImageView(isDisabled: onboardingValues.archiveName.isEmpty, text: "Done", rightImage: Image(.onboardingCheckmark), action: nextButton)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

#Preview {
    var onboardingViewModel = OnboardingArchiveViewModel(username: "none", password: "none")
    onboardingViewModel.pendingArchives = [
        OnboardingPendingArchives(fullname: "Documents", accessType: "viewer"),
        OnboardingPendingArchives(fullname: "Files", accessType: "admin"),
        OnboardingPendingArchives(fullname: "Photos", accessType: "editor")
        ]
    
    return ZStack {
        Color(.primary)
        OnboardingCongratulationsView(onboardingValues: onboardingViewModel) {
            
        } nextButton: {
            
        }
    }
    .ignoresSafeArea()
}
