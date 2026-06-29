//
//  RedesignDashboardHeader.swift
//  Permanent
//
//  Gradient nav bar shared by Frames A/B/C/D:
//  hamburger · "My Dashboard" · person. Identical across all dashboard states.
//

import SwiftUI

struct RedesignDashboardHeader: View {
    var onMenu: () -> Void = {}
    var onProfile: () -> Void = {}
    /// When false the left hamburger is hidden (an invisible 48pt spacer keeps the
    /// title centered) — used in the no-archive onboarding state where there is no
    /// drawer to open.
    var showsMenu: Bool = true

    var body: some View {
        // Nav row height 64, padding top 2 / bottom 10 / left+right 8,
        // space-between, items top-aligned.
        HStack(alignment: .top, spacing: 0) {
            if showsMenu {
                Button(action: onMenu) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                }
            } else {
                // Invisible placeholder keeps "My Dashboard" centered.
                Color.clear.frame(width: 48, height: 48)
            }

            Spacer(minLength: 0)

            Text("My Dashboard")
                .font(.custom(FontName.usualMedium.rawValue, fixedSize: 16))
                .tracking(-0.16)
                .foregroundColor(.white)
                .frame(height: 24)
                .padding(.top, 12) // visually centers the 24pt text within the 48pt tap rows

            Spacer(minLength: 0)

            Button(action: onProfile) {
                profileIcon
            }
        }
        .padding(.top, 2)
        .padding(.bottom, 10)
        .padding(.horizontal, 8)
        .frame(height: 64, alignment: .top)
        .background(RedesignGradient.header)
    }

    private var profileIcon: some View {
        Image(systemName: "person")
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.white)
            .frame(width: 48, height: 48)
    }
}

#Preview {
    VStack(spacing: 0) {
        RedesignDashboardHeader()
        Spacer()
    }
    .background(RedesignColor.whiteGray)
}
