//
//  OnboardingInvitedWelcomeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.07.2024.

import SwiftUI
import UIKit

struct OnboardingInvitedWelcomeView: View {
    var onboardingStorageValues: OnboardingArchiveViewModel
    @State private var dynamicHeight: CGFloat = 0
    var buttonAction: (() -> Void)
    
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
                    preText: "Hello, ",
                    boldText: "\(onboardingStorageValues.fullName)",
                    postText: ".\nWelcome to\nPermanent!"
                )
                Text("You’ve been invited to collaborate on an archive as an archive member. A Permanent archive is the collection of digital materials about an individual, family or group, or organizational entity. Get started by accepting an invitation, or by creating a new archive of your own.")
                    .textStyle(UsualSmallXRegularTextStyle())
                    .foregroundColor(.blue25)
                    .lineSpacing(8.0)
                    .multilineTextAlignment(.leading)
                ScrollViewReader { scrollReader in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            ForEach(onboardingStorageValues.allArchives) { archive in
                                if archive.status == .ok || archive.status == .pending {
                                    ArchiveDetailsView(archive: archive, showStatus: true, acceptArchive: {
                                        onboardingStorageValues.acceptPendingArchive(archive: archive)
                                    })
                                    Rectangle()
                                      .foregroundColor(.white)
                                      .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)
                                      .opacity(0.16)
                                      .cornerRadius(30)
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
                    Spacer()
                }
                .padding(.top, 10)
                Spacer(minLength: 100)
            }
            
            RoundButtonRightImageView(text: "Get started", action: buttonAction)
                .padding(.bottom, 40)
        }
    }
    
    var iPadBody: some View {
        HStack(alignment: .top, spacing: 64) {
            VStack() {
                HStack() {
                    OnboardingTitleTextView(
                        preText: "Hello, ",
                        boldText: "\(onboardingStorageValues.fullName)",
                        postText: ".\nWelcome to\nPermanent!"
                    )
                    Spacer()
                }
            }
            ZStack(alignment: .bottom) {
                VStack {
                    Text("You’ve been invited to collaborate on an archive as an archive member. A Permanent archive is the collection of digital materials about an individual, family or group, or organizational entity. Get started by accepting an invitation, or by creating a new archive of your own.")
                        .textStyle(UsualRegularTextStyle())
                        .foregroundColor(.blue25)
                        .lineSpacing(8.0)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.top, 10)
                HStack {
                    Spacer()
                    RoundButtonRightImageView(text: "Get started", action: buttonAction)
                        .frame(width: 243)
                        .padding(.bottom, 40)
                }
            }
        }
    }
}

#Preview {
    var onboardingViewModel = OnboardingArchiveViewModel(username: "none", password: "none")
    onboardingViewModel.fullName = "long archive name name name"
    onboardingViewModel.allArchives = [
        OnboardingInvitedArchives(fullname: "Documents", accessType: "viewer", status: ArchiveVOData.Status.pending, archiveID: 33),
        OnboardingInvitedArchives(fullname: "Photos", accessType: "editor", status: ArchiveVOData.Status.pending, archiveID: 22),
        OnboardingInvitedArchives(fullname: "Files", accessType: "owner", status: ArchiveVOData.Status.ok, archiveID: 333)
        ]
    
    return ZStack {
        Color(.primary)
        OnboardingInvitedWelcomeView(onboardingStorageValues: onboardingViewModel) {
            
        }
    }
    .ignoresSafeArea()
}
