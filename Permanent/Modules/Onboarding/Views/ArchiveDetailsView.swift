//
//  ArchiveDetailsView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 19.06.2024.

import SwiftUI

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
                    if archive.accessType.isNotEmpty && archive.status != .currentOwner {
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
                thumbnail
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
            .frame(height: 48)
        }
    }
}

#Preview {
    var archivePending = OnboardingArchive(fullname: "John Smith", accessType: "Viewer", status: ArchiveVOData.Status.currentOwner, archiveID: 1212)
    var archiveOk = OnboardingArchive(fullname: "John Smith", accessType: "Owner", status: ArchiveVOData.Status.ok, archiveID: 322)
    return ZStack {
        Color(.primary)
        VStack {
            ArchiveDetailsView(archive: archivePending, showStatus: true) {
                print("Accepted")
            }
            ArchiveDetailsView(archive: archiveOk, showStatus: true) {
                
            }
        }
    }
    .ignoresSafeArea()
}
