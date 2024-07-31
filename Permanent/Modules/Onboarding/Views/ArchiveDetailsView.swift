//
//  ArchiveDetailsView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 19.06.2024.

import SwiftUI
import SDWebImageSwiftUI

struct ArchiveDetailsView: View {
    var thumbnail: Image = Image(.onboardingArchiveBox)
    var archive: OnboardingArchive
    var showStatus: Bool = false
    var acceptArchive: (() -> Void) = { }
    
    
    var body: some View {
        if Constants.Design.isPhone {
            HStack(alignment: .center, spacing: 16) {
                thumbnail
                VStack(alignment: .leading, spacing: 4) {
                    Text("The \(archive.fullname) Archive")
                        .textStyle(UsualSmallXMediumTextStyle())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .lineLimit(1)
                    if archive.accessType.isNotEmpty && !archive.accessType.lowercased().contains("owner") {
                        Text("Invited as \(archive.accessType)")
                            .textStyle(UsualSmallXXXRegularTextStyle())
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .lineLimit(1)
                    }
                }
                if showStatus {
                    if archive.status == .ok {
                        HStack(spacing: 0) {
                            Text("Accepted")
                                .textStyle(UsualSmallXXXSemiBoldTextStyle())
                                .foregroundColor(Color(red: 0.2, green: 0.84, blue: 0.52))
                                .padding(.horizontal, -10)
                        }
                        Image(.onboardingCheckmark)
                            .renderingMode(.template)
                            .foregroundColor(Color(red: 0.2, green: 0.84, blue: 0.52))
                            .frame(width: 24, height: 24)
                    } else if archive.status == .pending {
                        Button(action: acceptArchive) {
                            HStack(spacing: 0) {
                                Text("Accept")
                                    .textStyle(UsualSmallXXXSemiBoldTextStyle())
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .inset(by: 0.5)
                                    .stroke(.white.opacity(0.32), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .frame(height: 40)
        } else {
            HStack(alignment: .center, spacing: 16) {
                if archive.isThumbnailGenerated {
                    WebImage(url: URL(string: archive.thumbnailURL))
                        .resizable()
                        .foregroundColor(.blue900)
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .cornerRadius(8.0)
                } else {
                        thumbnail
                }
                if showStatus {
                    VStack(spacing: 5) {
                        HStack {
                            Text("The ")
                            + Text("\(archive.fullname)")
                                .bold()
                            + Text(" Archive")
                        }
                        .font(
                            .custom(
                                "Usual-Regular",
                                fixedSize: 16)
                        )
                        .foregroundColor(.white)
                        .accentColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(8.0)
                        Text("Invited as \(archive.accessType)")
                            .textStyle(UsualSmallXRegularTextStyle())
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .lineLimit(1)
                    }
                    if archive.status == .ok {
                        HStack(spacing: 0) {
                            Text("Accepted")
                                .textStyle(UsualSmallXXXSemiBoldTextStyle())
                                .foregroundColor(Color(red: 0.2, green: 0.84, blue: 0.52))
                                .padding(.horizontal, -10)
                        }
                        Image(.onboardingCheckmark)
                            .renderingMode(.template)
                            .foregroundColor(Color(red: 0.2, green: 0.84, blue: 0.52))
                            .frame(width: 24, height: 24)
                    } else if archive.status == .pending {
                        Button(action: acceptArchive) {
                            HStack(spacing: 0) {
                                Text("Accept")
                                    .textStyle(UsualSmallXXXSemiBoldTextStyle())
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .inset(by: 0.5)
                                    .stroke(.white.opacity(0.32), lineWidth: 1)
                            )
                        }
                    }
                } else {
                    HStack {
                        HStack {
                            Text("The ")
                            + Text("\(archive.fullname)")
                                .bold()
                            + Text(" Archive")
                        }
                        .font(
                            .custom(
                                "Usual-Regular",
                                fixedSize: 16)
                        )
                        .foregroundColor(.white)
                        .accentColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(8.0)
                        Spacer()
                    }
                    if archive.accessType.isNotEmpty {
                        AccessRoleChipView(text: archive.accessType, textColor: .white)
                    }
                }
            }
            .frame(height: 48)
        }
    }
}

#Preview {
    var archivePending = OnboardingArchive(fullname: "John Smith", accessType: "Viewer", status: ArchiveVOData.Status.ok, archiveID: 1212, thumbnailURL: "", isThumbnailGenerated: false)
    var archiveSecondPending = OnboardingArchive(fullname: "John Smith", accessType: "Viewer", status: ArchiveVOData.Status.pending, archiveID: 1212, thumbnailURL: "", isThumbnailGenerated: false)
    var archiveOk = OnboardingArchive(fullname: "John Wade", accessType: "Owner", status: ArchiveVOData.Status.ok, archiveID: 322, thumbnailURL: "https://stagingcdn.permanent.org/018i-0000.thumb.w500?t=1753775559&Expires=1753775559&Signature=fPtRSvSdX1~fd5Bw8MlaUpJhUanzE0o~WM2k92IPMtscIzHJMybFcPh6aCXbASL777fvn5GXOv2UPdSMSzA0UPCXLy6pXcl4iiwFSbyiS7Zw5kUCIQdf45y013nos4CBM9pnl1UcfWwUJGI~gu7Vf5FwrZb3sEsXq2FVf2YN96WbIpFKGWo8sdlC4oN~ubIpmVsoUQDZ-F~jwmI2hfjYwXom8KXU4c70C2BmeF6qrLdneANmeR4kOqoQa78VLJRMII-nu75TEHpnhhm400fMZ61Om-rFLirsdhdrPfwFmfigd1ir8ja3iaJzmXSLD6LA8CwgjMMN1tBWf4qXUmddIw__&Key-Pair-Id=APKAJP2D34UGZ6IG443Q", isThumbnailGenerated: true)
    return ZStack {
        Color(.primary)
        VStack {
            ArchiveDetailsView(archive: archivePending, showStatus: true) {
                print("Accepted")
            }
            ArchiveDetailsView(archive: archiveSecondPending, showStatus: false) {
                print("Accepted")
            }
            ArchiveDetailsView(archive: archiveOk, showStatus: false) {
                
            }
        }
    }
    .ignoresSafeArea()
}
