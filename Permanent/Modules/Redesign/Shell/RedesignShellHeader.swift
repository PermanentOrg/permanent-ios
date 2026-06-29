//
//  RedesignShellHeader.swift
//  Permanent
//
//  One shared flat redesign header rendered ONCE by the app shell, above BOTH
//  the Dashboard and Files tabs. Dark-blue gradient bar, centered white title.
//  Only the title + trailing slot + content below change per tab; the chrome is
//  identical.
//
//  The action buttons (hamburger / search / person) are flat white SF Symbols on
//  the gradient, matching the Figma header (node 25381:33978) — no circle / glass
//  chrome. (The sheet dismiss "✕" buttons keep their Liquid Glass treatment via
//  `redesignDismissGlass()`; that's a separate component.)
//
//  Only reachable when `DashboardRedesign.isEnabled`.
//

import SwiftUI

/// Shared metrics for the redesign shell header. Exposed so the UIKit drawer can
/// align its slide-in / dim overlay to the bottom of the SwiftUI header.
enum RedesignShellHeaderMetrics {
    static let height: CGFloat = 64
}

struct RedesignShellHeader<Trailing: View>: View {
    let title: String
    var onMenu: () -> Void = {}
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        // Mirrors RedesignDashboardHeader: 64pt row, top-aligned tap targets,
        // centered 24pt title visually centered in the 48pt tap rows.
        HStack(alignment: .top, spacing: 0) {
            RedesignShellHeaderButton(
                systemName: "line.3.horizontal",
                accessibilityID: "shellMenuButton",
                action: onMenu
            )

            Spacer(minLength: 0)

            Text(title)
                .font(.custom(FontName.usualMedium.rawValue, fixedSize: 16))
                .tracking(-0.16)
                .foregroundColor(.white)
                .frame(height: 24)
                .padding(.top, 12) // visually centers the 24pt text within the 48pt tap rows

            Spacer(minLength: 0)

            // Trailing actions occupy the same mirrored width as the leading
            // hamburger so the title stays optically centered.
            HStack(spacing: 4) {
                trailing()
            }
            .frame(minWidth: 48, alignment: .trailing)
        }
        .padding(.top, 2)
        .padding(.bottom, 10)
        .padding(.horizontal, 8)
        .frame(height: RedesignShellHeaderMetrics.height, alignment: .top)
        .background(RedesignGradient.header)
    }
}

/// A flat header action button matching the Figma header (node 25381:33978): a
/// white glyph centered in a 48pt tap row, directly on the gradient — no circle
/// or glass chrome. The glyph is an SF Symbol (hamburger / search / person) or a
/// bundled asset image.
struct RedesignShellHeaderButton: View {
    enum Icon {
        case system(String)
        case asset(String)
    }

    let icon: Icon
    var accessibilityID: String?
    let action: () -> Void

    init(systemName: String, accessibilityID: String? = nil, action: @escaping () -> Void) {
        self.icon = .system(systemName)
        self.accessibilityID = accessibilityID
        self.action = action
    }

    init(assetName: String, accessibilityID: String? = nil, action: @escaping () -> Void) {
        self.icon = .asset(assetName)
        self.accessibilityID = accessibilityID
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            glyph
                .foregroundStyle(Color.white)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityID ?? defaultID)
    }

    @ViewBuilder
    private var glyph: some View {
        switch icon {
        case .system(let name):
            Image(systemName: name)
                .font(.system(size: 16, weight: .regular))
        case .asset(let name):
            Image(name)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
        }
    }

    private var defaultID: String {
        switch icon {
        case .system(let name): return name
        case .asset(let name): return name
        }
    }
}

#Preview("Dashboard header") {
    VStack(spacing: 0) {
        RedesignShellHeader(title: "My Dashboard") {
            RedesignShellHeaderButton(systemName: "person") {}
        }
        Spacer()
    }
    .background(RedesignColor.whiteGray)
}

#Preview("Files header") {
    VStack(spacing: 0) {
        RedesignShellHeader(title: "Private Files") {
            RedesignShellHeaderButton(systemName: "magnifyingglass") {}
            RedesignShellHeaderButton(assetName: "settings") {}
        }
        Spacer()
    }
    .background(RedesignColor.whiteGray)
}
