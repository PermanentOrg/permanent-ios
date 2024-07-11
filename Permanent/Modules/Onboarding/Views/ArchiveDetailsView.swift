//
//  ArchiveDetailsView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 19.06.2024.

import SwiftUI

struct ArchiveDetailsView: View {
    var thumbnail: Image = Image(.onboardingArchiveBox)
    var pendingArchive: OnboardingPendingArchives
    
    var body: some View {
        if Constants.Design.isPhone {
            HStack(alignment: .center, spacing: 16) {
                thumbnail
                VStack(alignment: .leading) {
                    Text("The \(pendingArchive.fullname) Archive")
                        .textStyle(UsualSmallXMediumTextStyle())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .lineLimit(1)
                    if pendingArchive.accessType.isNotEmpty {
                        Text("Invited as \(pendingArchive.accessType)")
                            .textStyle(UsualSmallXXXRegularTextStyle())
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .lineLimit(1)
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
                        + Text("\(pendingArchive.fullname)")
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
                if pendingArchive.accessType.isNotEmpty {
                    AccessRoleChipView(text: pendingArchive.accessType, textColor: .white)
                }
            }
            .frame(height: 48)
        }
    }
}

#Preview {
    ZStack {
        Color(.primary)
        ArchiveDetailsView(pendingArchive: OnboardingPendingArchives(fullname: "John Smith", accessType: "Viewer"))
    }
    .ignoresSafeArea()
}
