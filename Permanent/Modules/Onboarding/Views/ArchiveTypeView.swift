//
//  ArchiveTypeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.04.2024.

import SwiftUI

struct ArchiveTypeView: View {
    var archiveType: ArchiveType
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top, spacing: 24) {
                archiveType.onboardingDescriptionIcon
                    .renderingMode(.template)
                    .frame(width: 24, height: 24)
                    .accentColor(.blue900)
                VStack(alignment: .leading, spacing: Constants.Design.isPhone ? 8 : 16) {
                    if Constants.Design.isPhone {
                        Text("\(archiveType.onboardingType)")
                            .textStyle(UsualSmallXMediumTextStyle())
                            .accentColor(.blue900)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                        Text("\(archiveType.onboardingDescription)")
                            .textStyle(UsualSmallXXXRegularTextStyle())
                            .accentColor(.blue400)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("\(archiveType.onboardingType)")
                            .textStyle(UsualMediumTextStyle())
                            .accentColor(.blue900)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)
                        Text("\(archiveType.onboardingDescription)")
                            .textStyle(UsualMediumRegularTextStyle())
                            .accentColor(.middleGray)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, Constants.Design.isPhone ? 24 : 32)
            Divider()
        }
        .frame(height: Constants.Design.isPhone ? 96 : 120)
    }
}
