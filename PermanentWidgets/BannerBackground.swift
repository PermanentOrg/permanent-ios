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

/// The Lock Screen banner's background, per `UploadActivityStyle.bannerBackground`.
///
/// `.systemGlass` deliberately draws **nothing** and only tints: on iOS 26 the container
/// iOS supplies is Liquid Glass, and any opaque background of ours would replace it —
/// which is exactly the bug this modifier exists to prevent. `.figmaLiteral` draws the
/// design's navy slab instead, via `containerBackground(for: .widget)` on iOS 17+ and an
/// ordinary background below that, since this target ships to 16.2.
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
        case .figmaLiteral:
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
