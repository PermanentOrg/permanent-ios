//
//  BannerBackground.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import SwiftUI
// `activityBackgroundTint` and `containerBackground(for: .widget)` both come from
// WidgetKit. They were reachable while this type shared a file with the Widget itself.
import WidgetKit

/// `.systemGlass` draws nothing and only tints, so iOS 26's Liquid Glass survives.
/// `.opaqueFill` draws the navy panel — `containerBackground` on 17+, `.background` below.
struct BannerBackground: ViewModifier {
    private var navySlab: some View {
        ZStack {
            UploadActivityStyle.lockScreenBackground
            UploadActivityStyle.lockScreenScrim
        }
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        switch UploadActivityStyle.bannerBackground {
        case .systemGlass:
            content.activityBackgroundTint(UploadActivityStyle.lockScreenGlassTint)
        case .opaqueFill:
            if #available(iOS 17.0, *) {
                content
                    .containerBackground(for: .widget) { navySlab }
                    .activityBackgroundTint(UploadActivityStyle.lockScreenGlassTint)
            } else {
                content
                    .background(navySlab)
                    .activityBackgroundTint(UploadActivityStyle.lockScreenGlassTint)
            }
        }
    }
}
