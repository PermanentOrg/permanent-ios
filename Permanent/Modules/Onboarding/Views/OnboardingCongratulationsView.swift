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
                HStack {
                    Text("Get started by uploading your first files, or learn more about your new archive by ")
                    + Text("[viewing our help articles here.](https://permanent.zohodesk.com/portal/en/kb/permanent-legacy-foundation)")
                        .underline()
                }
                .font(
                    .custom(
                        "Usual-Regular",
                        fixedSize: 14)
                )
                .foregroundColor(.blue25)
                .accentColor(.blue25)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(8.0)
                
                ScrollViewReader { scrollReader in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(onboardingValues.allArchives.sorted(by: {
                                let isFirstItem = $0.accessType.lowercased().contains("owner")
                                let isSecondItem = $1.accessType.lowercased().contains("owner")
                                
                                if isFirstItem == isSecondItem {
                                    return $0.accessType < $1.accessType
                                }
                                
                                return isFirstItem && !isSecondItem
                            })) { archive in
                                ArchiveDetailsView(archive: archive)
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
                SmallRoundButtonImageView(text: "Done", image: Image(.onboardingCheckmark),  action: nextButton)
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
                        if !onboardingValues.allArchives.isEmpty {
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 32) {
                                    ForEach(onboardingValues.allArchives.sorted(by: {
                                        let isFirstItem = $0.accessType.lowercased().contains("owner")
                                        let isSecondItem = $1.accessType.lowercased().contains("owner")
                                        
                                        if isFirstItem == isSecondItem {
                                            return $0.accessType < $1.accessType
                                        }
                                        
                                        return isFirstItem && !isSecondItem
                                    })) { archive in
                                        ArchiveDetailsView(archive: archive)
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
                        RoundButtonRightImageView(text: "Done", rightImage: Image(.onboardingCheckmark), action: nextButton)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

#Preview {
    var onboardingViewModel = OnboardingArchiveViewModel(username: "none", password: "none")
    onboardingViewModel.allArchives = [
        OnboardingArchive(fullname: "Documents", accessType: "owner", status: ArchiveVOData.Status.pending, archiveID: 33),
        OnboardingArchive(fullname: "Files", accessType: "admin", status: ArchiveVOData.Status.ok, archiveID: 222),
        OnboardingArchive(fullname: "Photos", accessType: "editor", status: ArchiveVOData.Status.pending, archiveID: 4444),
        OnboardingArchive(fullname: "Text", accessType: "owner", status: ArchiveVOData.Status.ok, archiveID: 4444)
        ]
    
    return ZStack {
        Color(.primary)
        OnboardingCongratulationsView(onboardingValues: onboardingViewModel) {
            
        } nextButton: {
            
        }
    }
    .ignoresSafeArea()
}
