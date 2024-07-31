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
    var nextButtonAction: (() -> Void)
    var newArchiveButtonAction: (() -> Void)
    
    var body: some View {
        if Constants.Design.isPhone {
            iPhoneBody
        } else {
            iPadBody
        }
    }
    
    var iPhoneBody: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { scrollReader in
                ScrollView(showsIndicators: false) {
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
                VStack(spacing: 20) {
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
                Spacer(minLength: 200)
            }
            
            VStack(spacing: 20) {
                RoundButtonRightImageView(isDisabled: !onboardingStorageValues.isArchiveAccepted, text: "Next", action: nextButtonAction)
                SmallRoundButtonImageView(type: .noColor, imagePlace: .onRight, text: "New Archive", image: Image(.onboardingPlus), action: newArchiveButtonAction)
            }
            .padding(.bottom, 40)
        }
    }
    
    var iPadBody: some View {
        HStack(alignment: .top, spacing: 64) {
            VStack(spacing: 32) {
                HStack() {
                    OnboardingTitleTextView(
                        preText: "Hello, ",
                        boldText: "\(onboardingStorageValues.fullName)",
                        postText: ".\nWelcome to\nPermanent!"
                    )
                    Spacer()
                }
                Text("You’ve been invited to collaborate on an archive as an archive member. A Permanent archive is the collection of digital materials about an individual, family or group, or organizational entity. Get started by accepting an invitation, or by creating a new archive of your own.")
                    .textStyle(UsualRegularTextStyle())
                    .foregroundColor(.blue25)
                    .lineSpacing(8.0)
                    .multilineTextAlignment(.leading)
            }
            ZStack(alignment: .bottom) {
                VStack {
                    VStack(spacing: 32) {
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
                    Spacer()
                }
                .padding(.top, 20)
                HStack(spacing: 32) {
                    SmallRoundButtonImageView(type: .noColor, imagePlace: .onRight, text: "Create new Archive", image: Image(.onboardingPlus), action: newArchiveButtonAction)
                    RoundButtonRightImageView(isDisabled: !onboardingStorageValues.isArchiveAccepted, text: "Next", action: nextButtonAction)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    var onboardingViewModel = OnboardingArchiveViewModel(username: "none", password: "none")
    onboardingViewModel.fullName = "long archive name name name"
    onboardingViewModel.allArchives = [
        OnboardingArchive(fullname: "Documents", accessType: "viewer", status: ArchiveVOData.Status.pending, archiveID: 33, thumbnailURL: "", isThumbnailGenerated: false),
        OnboardingArchive(fullname: "Photos", accessType: "editor", status: ArchiveVOData.Status.pending, archiveID: 22, thumbnailURL: "", isThumbnailGenerated: false),
        OnboardingArchive(fullname: "Files", accessType: "owner", status: ArchiveVOData.Status.ok, archiveID: 333, thumbnailURL: "https://stagingcdn.permanent.org/018i-0000.thumb.w500?t=1753775559&Expires=1753775559&Signature=fPtRSvSdX1~fd5Bw8MlaUpJhUanzE0o~WM2k92IPMtscIzHJMybFcPh6aCXbASL777fvn5GXOv2UPdSMSzA0UPCXLy6pXcl4iiwFSbyiS7Zw5kUCIQdf45y013nos4CBM9pnl1UcfWwUJGI~gu7Vf5FwrZb3sEsXq2FVf2YN96WbIpFKGWo8sdlC4oN~ubIpmVsoUQDZ-F~jwmI2hfjYwXom8KXU4c70C2BmeF6qrLdneANmeR4kOqoQa78VLJRMII-nu75TEHpnhhm400fMZ61Om-rFLirsdhdrPfwFmfigd1ir8ja3iaJzmXSLD6LA8CwgjMMN1tBWf4qXUmddIw__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q", isThumbnailGenerated: true)
        ]
    
    return ZStack {
        Color(.primary)
        OnboardingInvitedWelcomeView(onboardingStorageValues: onboardingViewModel) {
            
        } newArchiveButtonAction: {
            
        }
    }
    .ignoresSafeArea()
}
