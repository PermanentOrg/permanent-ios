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
    }
}

#Preview {
    ZStack {
        Color(.primary)
        ArchiveDetailsView(pendingArchive: OnboardingPendingArchives(fullname: "John Smith", accessType: "Viewer"))
    }
    .ignoresSafeArea()
}
