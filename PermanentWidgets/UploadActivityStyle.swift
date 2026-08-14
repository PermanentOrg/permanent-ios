//
//  UploadActivityStyle.swift
//  PermanentWidgets
//
//  Colours, gradients, fonts and metrics for the upload Live Activity. Not from the app's
//  Colors.swift: that is app-target only, and the widget extension cannot see it.
//

import SwiftUI

enum UploadActivityStyle {
    // MARK: - Labels

    /// Primary label colour.
    static let primaryLabel = Color.white
    /// De-emphasised labels: file name, item count, header count. Faint over a pale wallpaper,
    /// but contrast has to come from `lockScreenGlassTint`, not from raising this opacity.
    static let secondaryLabel = Color.white.opacity(0.48)

    // MARK: - Status accents

    /// Failure accent.
    static let failedAccent = Color(activityHex: 0xFF383C)
    /// The "Private" workspace badge.
    static let privateBadge = Color(activityHex: 0x6CE9A6)
    /// The "Shared" workspace badge.
    static let sharedBadge = Color(activityHex: 0xFEC84B)
    /// Lighter stop of the brand orange, used on its own for the paused state
    static let pausedAccent = Color(activityHex: 0xFFA142)

    // MARK: - Progress bar

    /// Unfilled portion of the progress bar.
    static let progressTrack = Color.white.opacity(0.16)
    static let barHeight: CGFloat = 6
    static let barTrackRadius: CGFloat = 12
    static let barFillRadius: CGFloat = 40

    /// The upload bar, #800080 to #FF9933. The design angles this 2° off horizontal;
    /// across a 6pt-tall bar that tilt is sub-pixel, so leading-to-trailing matches it.
    static let progressFill = LinearGradient(
        colors: [Color(activityHex: 0x800080), Color(activityHex: 0xFF9933)],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// The brand orange used by the progress ring and the folder glyph, #ED7B00 to
    /// #FFA142, running bottom-trailing to top-leading to match the ring asset.
    static let brandOrange = LinearGradient(
        colors: [Color(activityHex: 0xED7B00), Color(activityHex: 0xFFA142)],
        startPoint: UnitPoint(x: 0.75, y: 0.77),
        endPoint: UnitPoint(x: 0.21, y: 0.08)
    )

    /// A single colour expressed as a gradient, so status accents are
    /// interchangeable with the brand gradients at every use site.
    static func flat(_ color: Color) -> LinearGradient {
        LinearGradient(colors: [color, color], startPoint: .leading, endPoint: .trailing)
    }

    /// Bar fill per status: the purple→orange brand fill while active, a flat accent when
    /// terminal, which reads faster.
    static func progressFill(for status: UploadActivityAttributes.UploadStatus) -> LinearGradient {
        switch status {
        case .uploading, .processing: progressFill
        case .paused: brandOrange
        case .completed: flat(privateBadge)
        case .failed: flat(failedAccent)
        }
    }

    /// Tint for the progress ring. Unlike the bar, the ring is brand orange while
    /// uploading, matching the ring asset; the purple-to-orange fill is the bar's alone.
    static func ringTint(for status: UploadActivityAttributes.UploadStatus) -> LinearGradient {
        switch status {
        case .uploading, .processing, .paused: brandOrange
        case .completed: flat(privateBadge)
        case .failed: flat(failedAccent)
        }
    }

    // MARK: - Lock Screen background

    /// How the Lock Screen banner's background is drawn. A real choice, not a fallback pair.
    enum BannerBackgroundStyle {
        /// The design's opaque navy panel, ignoring the wallpaper. Not for iOS 26: an opaque
        /// `containerBackground` of our own opts the banner out of Liquid Glass.
        case opaqueFill

        /// Tint the system container rather than draw one — Liquid Glass on iOS 26, the plain
        /// system material below it. Brand colour comes from `lockScreenGlassTint`.
        case systemGlass
    }

    /// iOS 26 has Liquid Glass worth deferring to. Below it, tinting alone gives a flat
    /// material that is neither the design nor an improvement, so draw the design's panel.
    static var bannerBackground: BannerBackgroundStyle {
        if let forced = bannerBackgroundOverride { return forced }
        if #available(iOS 26.0, *) { return .systemGlass }
        return .opaqueFill
    }

    /// Force one style regardless of OS, to compare the two on one device.
    /// `nil` resolves from the version above.
    static let bannerBackgroundOverride: BannerBackgroundStyle? = nil

    // MARK: - Expanded island layout

    /// Which layout the expanded Dynamic Island uses. Derived from the upload status: the
    /// full folder card while uploading, the shorter pill row for every other state.
    enum ExpandedLayout {
        case folderCard
        case pillRow
    }

#if DEBUG
    /// Force one layout regardless of status, to inspect either on device. DEBUG-only:
    /// `.pillRow` during an upload drops the progress bar and folder card.
    static let expandedLayoutOverride: ExpandedLayout? = nil
#endif

    /// The layout for a given status, honouring the DEBUG override.
    static func expandedLayout(for status: UploadActivityAttributes.UploadStatus) -> ExpandedLayout {
#if DEBUG
        if let forced = expandedLayoutOverride { return forced }
#endif
        return status == .uploading ? .folderCard : .pillRow
    }

    /// Tint over the system container in `.systemGlass`; the alpha is the knob — lower shows
    /// more wallpaper, higher approaches the designed navy. Lighter stop, as dark navy dims.
    static let lockScreenGlassTint = Color(activityHex: 0x364493).opacity(0.25)

    /// The design's panel: #131B4A to #364493 under a flat 40% black scrim, running left to
    /// right tilted 8° down — hence the 0.43/0.57 y offsets. Used by `.opaqueFill`.
    static let lockScreenBackground = LinearGradient(
        colors: [Color(activityHex: 0x131B4A), Color(activityHex: 0x364493)],
        startPoint: UnitPoint(x: 0, y: 0.43),
        endPoint: UnitPoint(x: 1, y: 0.57)
    )
    static let lockScreenScrim = Color.black.opacity(0.4)
    static let lockScreenCornerRadius: CGFloat = 32

    // MARK: - Typography

    // SF Pro is the system font, so `.system(size:weight:)` matches the design directly.
    // Tracking is separate because SwiftUI exposes it as a view modifier.

    /// 17pt Medium — the header row.
    static let headerFont = Font.system(size: 17, weight: .medium)
    /// 17pt Bold — the emphasised status word in the pill row.
    static let headerEmphasisFont = Font.system(size: 17, weight: .bold)
    static let headerTracking: CGFloat = -0.68
    /// The design pins the header row to 22pt. SwiftUI's natural line height for 17pt is
    /// ~20.3, so pinning it is what keeps the banner at its designed 160pt.
    static let headerLineHeight: CGFloat = 22

    /// 12pt Regular — file name and the folder's item count.
    static let detailFont = Font.system(size: 12, weight: .regular)
    static let detailTracking: CGFloat = -0.24

    /// 12pt Semibold — percentage and folder name.
    static let emphasisFont = Font.system(size: 12, weight: .semibold)
    static let emphasisTracking: CGFloat = -0.48

    /// Live Activities are height-capped, so unbounded text is clipped rather than reflowed.
    /// xxLarge stays legible for most accessibility settings without hitting the cap.
    static let maxDynamicTypeSize = DynamicTypeSize.xxLarge

    // MARK: - Layout

    /// Dynamic Island, expanded.
    enum Expanded {
        static let spacing: CGFloat = 20
        static let verticalPadding: CGFloat = 32
        static let folderRowHeight: CGFloat = 42

        /// The design measures 40pt from the island's own edge to the content.
        static let horizontalPadding: CGFloat = 40
        /// ActivityKit already insets expanded-region content from that edge by roughly
        /// this much, so only the remainder is ours to add. Adjust here, not at a use site.
        static let systemRegionInset: CGFloat = 16
        static var regionHorizontalPadding: CGFloat {
            max(0, horizontalPadding - systemRegionInset)
        }
    }

    /// Dynamic Island, expanded at its minimum height (the pill row).
    enum Pill {
        static let verticalPadding: CGFloat = 24
        static let iconSpacing: CGFloat = 8
        static let markSize: CGFloat = 36

        static let leadingPadding: CGFloat = 27.5
        static let trailingPadding: CGFloat = 42
        static var regionLeadingPadding: CGFloat {
            max(0, leadingPadding - Expanded.systemRegionInset)
        }
        static var regionTrailingPadding: CGFloat {
            max(0, trailingPadding - Expanded.systemRegionInset)
        }
    }

    /// Lock Screen banner.
    enum LockScreen {
        static let spacing: CGFloat = 16
        static let padding: CGFloat = 24
        static let textBlockSpacing: CGFloat = 4
        static let fileRowSpacing: CGFloat = 8
        static let folderRowHeight: CGFloat = 34
    }

    /// Dynamic Island, collapsed. The ring's own geometry lives on
    /// `UploadProgressRing.Metrics`, where it is drawn.
    enum Compact {
        static let markHeight: CGFloat = 17.33
    }

    static let headerSpacing: CGFloat = 4
    static let folderTextSpacing: CGFloat = 4

    /// Aspect ratios of the Permanent swirl (55.721 × 42) and the folder glyph (48 × 42).
    /// Both are drawn height-first, so the width follows.
    static let brandMarkAspect: CGFloat = 55.721 / 42
    static let folderGlyphAspect: CGFloat = 48 / 42
}

// MARK: - Hex

private extension Color {
    /// 0xRRGGBB, in sRGB. Scoped to this file so it can't collide with a hex
    /// initialiser the app target may add later.
    init(activityHex hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
