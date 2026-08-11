//
//  UploadActivityStyle.swift
//  PermanentWidgets
//
//  Design tokens for the upload Live Activity, lifted from Figma frame 112916
//  (file lLHzIJcmkwkvdl3ipcjyKs, node 26268:46367). Every value here traces back
//  to a node in that frame — the node id is in the comment next to it. Change a
//  value here rather than at a use site so the three presentations stay in sync.
//
//  Nothing in this file can come from the app's `Colors.swift`: that lives in the
//  app target and the widget extension can't see it. These are also brand values
//  that exist nowhere else in the app (the swirl gradients, the purple→orange
//  progress fill), so there is no existing token to reuse.
//

import SwiftUI

enum UploadActivityStyle {
    // MARK: - Labels

    /// `Labels/Primary` — 26269:50898
    static let primaryLabel = Color.white
    /// 48% white, used for every de-emphasised label in the design — 26269:50899.
    ///
    /// Over Liquid Glass on a light wallpaper this reads faint. That is measured, and both
    /// obvious fixes were tried and rejected: raising it to 66% is near-invisible as a
    /// change (more white on near-white does nothing), and `.secondary` tracks the colour
    /// scheme rather than the wallpaper, so it fails over whichever backdrop the scheme
    /// doesn't match. Making it legible over an arbitrary wallpaper needs the banner to
    /// supply its own contrast — i.e. a darker `lockScreenGlassTint` — which trades against
    /// how glassy the banner looks. That is a design decision, not a code fix, so this stays
    /// at the design value until it is made.
    static let secondaryLabel = Color.white.opacity(0.48)

    // MARK: - Status accents

    /// `Accents/Red` — the only Figma variable in the frame that isn't a white tint
    static let failedAccent = Color(activityHex: 0xFF383C)
    /// 26269:50893 — the "Private" badge
    static let privateBadge = Color(activityHex: 0x6CE9A6)
    /// 26269:50861 — the "Shared" badge
    static let sharedBadge = Color(activityHex: 0xFEC84B)
    /// Lighter stop of the brand orange, used on its own for the paused state
    static let pausedAccent = Color(activityHex: 0xFFA142)

    // MARK: - Progress bar

    /// `White/16%` — 26269:50882
    static let progressTrack = Color.white.opacity(0.16)
    static let barHeight: CGFloat = 6
    static let barTrackRadius: CGFloat = 12
    static let barFillRadius: CGFloat = 40

    /// The upload bar: `linear-gradient(91.97deg, #800080, #FF9933)` — 26269:50883.
    /// 91.97° is 2° off horizontal; across a 6pt-tall bar that tilt is sub-pixel,
    /// so leading→trailing reproduces it exactly.
    static let progressFill = LinearGradient(
        colors: [Color(activityHex: 0x800080), Color(activityHex: 0xFF9933)],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// The brand orange used by the progress ring and the folder icon —
    /// `#ED7B00 → #FFA142`, running bottom-trailing to top-leading (ring SVG
    /// `paint0_linear_0_7`).
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

    /// Fill for the progress bar in a given status. Only `uploading` and
    /// `processing` get the purple→orange brand fill; terminal states read faster
    /// as a flat accent.
    static func progressFill(for status: UploadActivityAttributes.UploadStatus) -> LinearGradient {
        switch status {
        case .uploading, .processing: progressFill
        case .paused: brandOrange
        case .completed: flat(privateBadge)
        case .failed: flat(failedAccent)
        }
    }

    /// Tint for the progress ring. Unlike the bar, the ring is brand orange while
    /// uploading — that is what the ring assets use (`paint0_linear_0_7`), the
    /// purple→orange fill is the bar's alone.
    static func ringTint(for status: UploadActivityAttributes.UploadStatus) -> LinearGradient {
        switch status {
        case .uploading, .processing, .paused: brandOrange
        case .completed: flat(privateBadge)
        case .failed: flat(failedAccent)
        }
    }

    // MARK: - Lock Screen background

    /// How the Lock Screen banner's background is drawn. The two options are a real
    /// choice, not a fallback pair — see each case.
    enum BannerBackgroundStyle {
        /// Figma frame 26269:50826 exactly as drawn: an opaque navy slab. Note the
        /// frame also carries a `backdrop-blur-[25px]` that can have no effect
        /// behind a full-opacity fill, so "opaque" is the literal reading of the
        /// fills — but the blur suggests the designer had translucency in mind.
        ///
        /// Reproduces the design pixel-for-pixel, and ignores the wallpaper. On
        /// iOS 26 that reads as pre-Liquid-Glass, because drawing our own opaque
        /// `containerBackground` opts the banner out of the system's glass.
        case figmaLiteral

        /// Let iOS draw the container and only tint it. On iOS 26 that container is
        /// Liquid Glass, so the wallpaper reads through and refracts; on 16.2–25 it
        /// degrades to the system material with the same tint. The brand navy
        /// survives via `lockScreenGlassTint`.
        case systemGlass
    }

    /// Resolved from the OS, because the right answer differs by version: iOS 26 has
    /// Liquid Glass worth deferring to, and below it there is no glass to opt into —
    /// `.systemGlass` there would just be a flat system material, which is neither
    /// the design nor an improvement on it. So 26+ gets glass, older gets the frame
    /// as drawn.
    static var bannerBackground: BannerBackgroundStyle {
        if let forced = bannerBackgroundOverride { return forced }
        if #available(iOS 26.0, *) { return .systemGlass }
        return .figmaLiteral
    }

    /// Force one style regardless of OS, to compare the two on the same device.
    /// `nil` resolves from the version above.
    static let bannerBackgroundOverride: BannerBackgroundStyle? = nil

    // MARK: - Expanded island layout

    /// Which layout the expanded Dynamic Island uses. Normally derived from the
    /// upload status: the full folder card while uploading, the minimum-height pill
    /// row (26268:46410) for every other state.
    enum ExpandedLayout {
        case folderCard
        case pillRow
    }

#if DEBUG
    /// Set to `.pillRow` or `.folderCard` to force one layout regardless of status,
    /// so either can be inspected on device without engineering the upload state.
    ///
    /// Reaching `.pillRow` by hand is genuinely awkward — iOS hides an app's island
    /// presentation while that app is frontmost, a completed activity is already
    /// `.ended` so the island drops it quickly, and `dismissEndedActivities()`
    /// (UploadLiveActivityManager.swift:525) kills any ended activity as soon as you
    /// return to the app. Backgrounding mid-upload for ~35s is the only hand-reachable
    /// route (it goes stale → displays as paused).
    ///
    /// DEBUG-only on purpose: forcing `.pillRow` during an upload drops the progress
    /// bar and folder card that VSP-1801's acceptance criteria require, so it must not
    /// be shippable.
    static let expandedLayoutOverride: ExpandedLayout? = nil
#endif

    /// The layout for a given status, honouring the DEBUG override.
    static func expandedLayout(for status: UploadActivityAttributes.UploadStatus) -> ExpandedLayout {
#if DEBUG
        if let forced = expandedLayoutOverride { return forced }
#endif
        return status == .uploading ? .folderCard : .pillRow
    }

    /// Tint laid over the system container in `.systemGlass`. The **alpha is the
    /// knob**: lower lets more wallpaper through and looks glassier, higher pushes
    /// back toward the designed navy.
    ///
    /// **25%, set by the designer on 2026-08-11.** History: 0.55 read as a dark panel
    /// rather than glass next to a native iOS 26 control (Lucian, on device, 2026-08-10:
    /// "this is a little weird, I think we want that native look, a little small alpha
    /// blue from Permanent"); 0.18 was the reaction to that and looked right on device;
    /// the designer then chose 25%. Uses the design gradient's *lighter* stop (`#364493`)
    /// rather than the midpoint, because at low alpha a very dark navy reads as dimming
    /// rather than as a blue tint.
    static let lockScreenGlassTint = Color(activityHex: 0x364493).opacity(0.25)

    /// 26269:50826 — `linear-gradient(98.23deg, #131B4A, #364493)` under a flat
    /// 40% black scrim. 98.23° resolves to a left→right run tilted 8° down,
    /// which is where the 0.43/0.57 y offsets come from. Used by `.figmaLiteral`.
    static let lockScreenBackground = LinearGradient(
        colors: [Color(activityHex: 0x131B4A), Color(activityHex: 0x364493)],
        startPoint: UnitPoint(x: 0, y: 0.43),
        endPoint: UnitPoint(x: 1, y: 0.57)
    )
    static let lockScreenScrim = Color.black.opacity(0.4)
    static let lockScreenCornerRadius: CGFloat = 32

    // MARK: - Typography
    //
    // SF Pro is the system font, so `.system(size:weight:)` is a direct match:
    // Figma's `font-[510]` is Medium and `font-[590]` is Semibold. Tracking is
    // applied separately because SwiftUI exposes it as a view modifier.

    /// 17pt Medium — the "Uploading to Permanent" / "3 of 5" row (26269:50898)
    static let headerFont = Font.system(size: 17, weight: .medium)
    /// 17pt Bold — the emphasised status word in the pill row (26268:46411)
    static let headerEmphasisFont = Font.system(size: 17, weight: .bold)
    static let headerTracking: CGFloat = -0.68
    /// Figma's explicit `leading-[22px]` on the header row (26269:50898). SwiftUI's
    /// natural line height for 17pt is ~20.3, so this is pinned to keep the banner
    /// at its designed 160pt.
    static let headerLineHeight: CGFloat = 22

    /// 12pt Regular — file name, "32 items • Private" (26269:50846)
    static let detailFont = Font.system(size: 12, weight: .regular)
    static let detailTracking: CGFloat = -0.24

    /// 12pt Semibold — percentage, folder name (26269:50847)
    static let emphasisFont = Font.system(size: 12, weight: .semibold)
    static let emphasisTracking: CGFloat = -0.48

    /// Live Activities have a hard height cap, so text that grows without limit
    /// gets clipped by the system rather than reflowed. Allowing growth up to
    /// xxLarge keeps the layout legible for most accessibility settings while
    /// staying inside the cap.
    static let maxDynamicTypeSize = DynamicTypeSize.xxLarge

    // MARK: - Layout

    /// Dynamic Island, expanded — 26269:50872
    enum Expanded {
        static let spacing: CGFloat = 20
        static let verticalPadding: CGFloat = 32
        static let folderRowHeight: CGFloat = 42

        /// Figma measures 40pt from the island's own edge to the content.
        static let horizontalPadding: CGFloat = 40
        /// ActivityKit already insets expanded-region content from that edge by
        /// roughly this much, so only the remainder is ours to add. Verified
        /// against a running activity — adjust here, not at the use site.
        static let systemRegionInset: CGFloat = 16
        static var regionHorizontalPadding: CGFloat {
            max(0, horizontalPadding - systemRegionInset)
        }
    }

    /// Dynamic Island, expanded at minimum height (the pill row) — 26268:46410
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

    /// Lock Screen banner — 26269:50849
    enum LockScreen {
        static let spacing: CGFloat = 16
        static let padding: CGFloat = 24
        static let textBlockSpacing: CGFloat = 4
        static let fileRowSpacing: CGFloat = 8
        static let folderRowHeight: CGFloat = 34
    }

    /// Dynamic Island, collapsed — 26268:46369. The ring's own geometry lives on
    /// `UploadProgressRing.Metrics`, which is where it is drawn.
    enum Compact {
        static let markHeight: CGFloat = 17.33
    }

    static let headerSpacing: CGFloat = 4
    static let folderTextSpacing: CGFloat = 4

    /// Aspect ratio of the Permanent swirl (55.721 × 42) and of the folder
    /// glyph (48 × 42). Both are drawn height-first, so the width follows.
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
