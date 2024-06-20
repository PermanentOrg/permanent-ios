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

        }
    }
}
