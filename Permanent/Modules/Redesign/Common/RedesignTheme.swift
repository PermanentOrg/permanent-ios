//
//  RedesignTheme.swift
//  Permanent
//
//  Design tokens for the redesigned onboarding-dashboard (Frames A–D).
//  Single source of truth for the new colors, gradients, the Widget Drop
//  shadow, and spacing constants used across the Redesign module.
//
//  All values mirror PIXEL_SPEC.md exactly (390×844, 1pt = 1px).
//

import SwiftUI

// MARK: - Hex Color helper

extension Color {
    /// Creates a Color from a 6-digit hex string (e.g. "#364493" or "364493").
    init(redesignHex hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

// MARK: - Redesign palette

enum RedesignColor {
    // Existing tokens (re-declared here as exact hex so the module is self-contained
    // and matches the spec even if asset-catalog values drift).
    static let darkBlue = Color(redesignHex: "131B4A")    // blue900
    static let blue600 = Color(redesignHex: "5A5F80")
    static let blue400 = Color(redesignHex: "898DA4")
    static let blue300 = Color(redesignHex: "A1A4B7")
    static let blue100 = Color(redesignHex: "D0D1DB")
    static let blue50 = Color(redesignHex: "E7E8ED")
    static let whiteGray = Color(redesignHex: "F4F6FD")   // blue25 / background
    static let tangerine = Color(redesignHex: "FF9933")
    static let success500 = Color(redesignHex: "12B76A")
    static let error500 = Color(redesignHex: "F04438")
    static let white = Color.white

    // NEW colors required by the redesign.
    static let blueGradientEnd = Color(redesignHex: "364493")  // header / button gradient end
    static let purple = Color(redesignHex: "800080")
    static let purpleCardEnd = Color(redesignHex: "B843A6")

    // Skeleton (Frame A) neutral fills.
    static let skeletonAvatar = Color(redesignHex: "E3E5EC")
    static let skeletonCardTop = Color(redesignHex: "E7E8ED")
    static let skeletonCardBottom = Color(redesignHex: "EDEFF6")
}

// MARK: - Angular linear gradients

/// Builds a SwiftUI `LinearGradient` matching a CSS `linear-gradient(angleDegrees, ...)`.
///
/// CSS angle is measured clockwise from the top (0° points up / bottom→top).
/// We map that to SwiftUI's y-down unit space: the gradient direction is
/// `(sin θ, -cos θ)` and we anchor symmetrically around the (0.5, 0.5) center.
func redesignLinearGradient(angleDegrees: Double, stops: [Gradient.Stop]) -> LinearGradient {
    let radians = angleDegrees * .pi / 180.0
    let dx = sin(radians)
    let dy = -cos(radians)
    // Half-length 0.5 along the direction keeps the gradient line centered.
    let start = UnitPoint(x: 0.5 - dx * 0.5, y: 0.5 - dy * 0.5)
    let end = UnitPoint(x: 0.5 + dx * 0.5, y: 0.5 + dy * 0.5)
    return LinearGradient(stops: stops, startPoint: start, endPoint: end)
}

func redesignLinearGradient(angleDegrees: Double, colors: [Color]) -> LinearGradient {
    let stops = colors.enumerated().map { index, color in
        Gradient.Stop(color: color, location: colors.count <= 1 ? 0 : Double(index) / Double(colors.count - 1))
    }
    return redesignLinearGradient(angleDegrees: angleDegrees, stops: stops)
}

enum RedesignGradient {
    // The spec describes "base #131B4A→#364493 + flat 20% black overlay".
    // We pre-multiply the 20% black overlay into the stop colors so a single
    // LinearGradient renders the effective result (≈ #0E153B → #2A356F).
    private static func darkenedBlue(angle: Double) -> LinearGradient {
        redesignLinearGradient(
            angleDegrees: angle,
            colors: [
                RedesignColor.darkBlue.opacity(1).blendedWithBlack(0.20),
                RedesignColor.blueGradientEnd.blendedWithBlack(0.20)
            ]
        )
    }

    /// Header bar: 102.34° #131B4A→#364493 + 20% black.
    static var header: LinearGradient { darkenedBlue(angle: 102.34) }

    /// Frame C primary button: 104.09° + 20% black.
    static var primaryButtonC: LinearGradient { darkenedBlue(angle: 104.09) }

    /// Frame D primary button: 109.43° + 20% black.
    static var primaryButtonD: LinearGradient { darkenedBlue(angle: 109.43) }

    /// Frame C hero title fill: 108.69° #800080 @13.25% → #FF9933 @92.4%.
    static var heroTitlePurpleOrange: LinearGradient {
        redesignLinearGradient(
            angleDegrees: 108.69,
            stops: [
                Gradient.Stop(color: RedesignColor.purple, location: 0.1325),
                Gradient.Stop(color: RedesignColor.tangerine, location: 0.924)
            ]
        )
    }

    /// Frame D hero title fill: 100.36° #131B4A→#364493.
    static var heroTitleDarkBlue: LinearGradient {
        redesignLinearGradient(
            angleDegrees: 100.36,
            colors: [RedesignColor.darkBlue, RedesignColor.blueGradientEnd]
        )
    }

    /// Avatar / heart / archive icon fill: 103.06° #800080 0% → #FF9933 100%.
    static var iconPurpleOrange: LinearGradient {
        redesignLinearGradient(
            angleDegrees: 103.06,
            colors: [RedesignColor.purple, RedesignColor.tangerine]
        )
    }

    /// Purple goals card bg (optional): 49.66° #800080 @4.6% → #B843A6 @95.5%.
    static var purpleGoalsCard: LinearGradient {
        redesignLinearGradient(
            angleDegrees: 49.66,
            stops: [
                Gradient.Stop(color: RedesignColor.purple, location: 0.046),
                Gradient.Stop(color: RedesignColor.purpleCardEnd, location: 0.955)
            ]
        )
    }

    /// "You're all caught up." text fill: 160.61° #800080 → #FF9933.
    static var caughtUp: LinearGradient {
        redesignLinearGradient(
            angleDegrees: 160.61,
            colors: [RedesignColor.purple, RedesignColor.tangerine]
        )
    }

    /// Selected goal-chip text/check fill: #800080 → #B843A6.
    static var goalChipSelected: LinearGradient {
        redesignLinearGradient(
            angleDegrees: 108.0,
            colors: [RedesignColor.purple, RedesignColor.purpleCardEnd]
        )
    }

    /// Frame A skeleton card subtle vertical gradient #E7E8ED→#EDEFF6.
    static var skeletonCard: LinearGradient {
        LinearGradient(
            colors: [RedesignColor.skeletonCardTop, RedesignColor.skeletonCardBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Frame D scrim: 96.12° rgba(19,27,74,.48)→rgba(54,68,147,.48).
    static var scrim: LinearGradient {
        redesignLinearGradient(
            angleDegrees: 96.12,
            colors: [
                RedesignColor.darkBlue.opacity(0.48),
                RedesignColor.blueGradientEnd.opacity(0.48)
            ]
        )
    }
}

private extension Color {
    /// Approximates a flat black overlay at the given opacity by blending the
    /// receiver toward black: result = color * (1 - amount).
    func blendedWithBlack(_ amount: Double) -> Color {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let f = CGFloat(1 - amount)
        return Color(.sRGB, red: Double(r * f), green: Double(g * f), blue: Double(b * f), opacity: Double(a))
    }
}

// MARK: - Widget Drop shadow

extension View {
    /// The standard "Widget Drop" shadow applied to every white card:
    /// `0px 1px 0 rgba(0,0,0,0.04)` + `0px 12px 4px -8px rgba(0,0,0,0.02)`.
    func widgetDropShadow() -> some View {
        self
            .shadow(color: Color.black.opacity(0.04), radius: 0, x: 0, y: 1)
            // CSS "0 12px 4px -8px": the -8 spread pulls the shadow in so it only
            // peeks ~4px below the card. SwiftUI has no spread, so approximate with
            // a small offset + blur — otherwise the shadow blooms into the 4pt gaps
            // between connected segments and makes them look separated.
            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 3)
    }
}

// MARK: - Liquid Glass dismiss button

/// iOS 26 Liquid Glass circle for the sheet "✕" dismiss buttons (dark-blue glyph
/// on a light sheet). Falls back to a solid white circle + soft shadow on earlier
/// iOS. Apply to the glyph after sizing it (e.g. `.frame(44×44).modifier(...)`).
struct RedesignDismissGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: .circle)
        } else {
            content.background(
                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
            )
        }
    }
}

extension View {
    /// Wraps a sized glyph in the Liquid Glass dismiss circle.
    func redesignDismissGlass() -> some View { modifier(RedesignDismissGlass()) }
}

// MARK: - Spacing

enum RedesignSpacing {
    static let contentPadding: CGFloat = 24
    static let cardRadius: CGFloat = 24
    static let buttonRadius: CGFloat = 12
    static let buttonHeight: CGFloat = 56
    static let sectionGap: CGFloat = 24
    static let sheetTopRadius: CGFloat = 38
    static let chipRadius: CGFloat = 99
    static let chipHeight: CGFloat = 32
}

// MARK: - Preview helper

/// Lets a `#Preview` drive an interactive `@Binding` (e.g. chip selection).
/// Previously provided by the now-removed DashboardPrototype module; kept here so
/// the Redesign module's previews are self-contained.
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ initialValue: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View { content($value) }
}
