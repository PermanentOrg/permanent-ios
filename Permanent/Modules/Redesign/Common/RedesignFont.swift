//
//  RedesignFont.swift
//  Permanent
//
//  Hero serif font helper + gradient title renderer for the redesign.
//
//  HERO SERIF = "Gyst Variable" (variable font, weight axis 100–700).
//  Files provided: GystVariableRoman-Light.otf (PostScript "GystVariableRoman-Light")
//  and GystVariableItalic-LightItalic.otf (PostScript "GystVariableItalic-LightItalic"),
//  staged in Permanent/Modules/Redesign/Common/Fonts/. Because they are variable we
//  render them at the design's Medium weight (wght = 500) via the 'wght' variation axis,
//  even though the files default to Light (100). Until the .otf files have target
//  membership, this helper falls back to the system serif (New York).
//
//  ── REMAINING STEP TO ACTIVATE GYST ──────────────────────────────────────────
//  In Xcode, select the two .otf files in Common/Fonts/ → File inspector →
//  tick Target Membership: Permanent. (UIAppFonts entries are already added to
//  Permanent/Resources/Assets/Info.plist.) Then the hero titles render in Gyst Medium.
//  ──────────────────────────────────────────────────────────────────────────────

import SwiftUI
import UIKit

enum RedesignSerifFont {
    /// Exact PostScript names of the provided Gyst Variable files.
    static let regularPostScript = "GystVariableRoman-Light"
    static let italicPostScript  = "GystVariableItalic-LightItalic"

    /// The OpenType 'wght' variable axis identifier (FourCharCode for "wght").
    private static let weightAxis = 0x77676874

    static func isRegistered(_ name: String) -> Bool {
        UIFont.familyNames.contains { family in
            UIFont.fontNames(forFamilyName: family).contains(name)
        }
    }

    /// A `UIFont` for Gyst at the given size and variable weight, or `nil` when
    /// the Gyst files are not yet registered (no target membership / not bundled).
    static func uiFont(size: CGFloat, weight: CGFloat, italic: Bool) -> UIFont? {
        let name = italic ? italicPostScript : regularPostScript
        guard isRegistered(name) else { return nil }
        let descriptor = UIFontDescriptor(fontAttributes: [
            .name: name,
            kCTFontVariationAttribute as UIFontDescriptor.AttributeName: [weightAxis: weight]
        ])
        return UIFont(descriptor: descriptor, size: size)
    }
}

enum RedesignFont {
    /// Maps a SwiftUI weight to the numeric 'wght' axis value (100–700).
    private static func axisValue(for weight: SwiftUI.Font.Weight) -> CGFloat {
        switch weight {
        case .ultraLight: return 100
        case .thin:       return 200
        case .light:      return 300
        case .regular:    return 400
        case .medium:     return 500
        case .semibold:   return 600
        case .bold:       return 700
        default:          return 500
        }
    }

    /// Hero serif. Uses Gyst Variable (at the requested weight via its variable
    /// axis) if registered, else New York (system serif). `.italic()` is applied
    /// to the fallback so italic segments still slant.
    /// `SwiftUI.Font` is fully qualified because the app declares its own
    /// `Permanent.Font` type in Constants.swift, which would otherwise shadow it.
    static func serif(size: CGFloat, weight: SwiftUI.Font.Weight = .medium, italic: Bool = false) -> SwiftUI.Font {
        if let ui = RedesignSerifFont.uiFont(size: size, weight: axisValue(for: weight), italic: italic) {
            return SwiftUI.Font(ui)
        }
        let base = SwiftUI.Font.system(size: size, weight: weight, design: .serif)
        return italic ? base.italic() : base
    }
}

// MARK: - Gradient title

/// One run within a gradient hero title: text plus whether it is italic.
struct RedesignTitleRun: Identifiable {
    let id = UUID()
    let text: String
    let italic: Bool

    init(_ text: String, italic: Bool = false) {
        self.text = text
        self.italic = italic
    }
}

/// One visual line of a hero title (a sequence of runs rendered inline).
struct RedesignTitleLine: Identifiable {
    let id = UUID()
    let runs: [RedesignTitleRun]

    init(_ runs: [RedesignTitleRun]) {
        self.runs = runs
    }
}

/// Renders a multi-line serif title where individual runs may be italic, with a
/// single gradient fill applied across the ENTIRE text block (not per line).
///
/// Implementation: the text is drawn with concatenated `Text` runs (so per-run
/// italic works and the system handles inline layout/wrapping), then the whole
/// block is used as a mask over the gradient so the fill spans every line.
struct RedesignGradientTitle: View {
    let lines: [RedesignTitleLine]
    let fontSize: CGFloat
    let lineHeight: CGFloat
    let tracking: CGFloat
    let gradient: LinearGradient
    var alignment: TextAlignment = .center

    init(lines: [RedesignTitleLine],
         fontSize: CGFloat = 40,
         lineHeight: CGFloat = 40,
         tracking: CGFloat = -1.2,
         gradient: LinearGradient,
         alignment: TextAlignment = .center) {
        self.lines = lines
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.tracking = tracking
        self.gradient = gradient
        self.alignment = alignment
    }

    /// Builds a single `Text` for one line by concatenating its runs.
    private func text(for line: RedesignTitleLine) -> Text {
        line.runs.reduce(Text("")) { partial, run in
            partial + Text(run.text)
                .font(RedesignFont.serif(size: fontSize, italic: run.italic))
        }
    }

    /// Vertical padding to fake the requested line-height when it is smaller
    /// than the font's natural leading (lineHeight 40 on a 40pt font is tight).
    private var verticalLineSpacing: CGFloat {
        lineHeight - fontSize
    }

    private var content: some View {
        VStack(alignment: horizontalAlignment, spacing: max(0, verticalLineSpacing)) {
            ForEach(lines) { line in
                text(for: line)
                    .tracking(tracking)
                    .multilineTextAlignment(alignment)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var horizontalAlignment: HorizontalAlignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        case .center: return .center
        }
    }

    var body: some View {
        content
            .foregroundColor(.clear)
            .overlay(
                gradient.mask(content)
            )
    }
}

#Preview("Gradient titles") {
    VStack(spacing: 40) {
        RedesignGradientTitle(
            lines: [
                RedesignTitleLine([RedesignTitleRun("Let's begin")]),
                RedesignTitleLine([RedesignTitleRun("your "), RedesignTitleRun("archive", italic: true)])
            ],
            gradient: RedesignGradient.heroTitlePurpleOrange
        )
        RedesignGradientTitle(
            lines: [
                RedesignTitleLine([RedesignTitleRun("What do you plan")]),
                RedesignTitleLine([
                    RedesignTitleRun("to "),
                    RedesignTitleRun("capture", italic: true),
                    RedesignTitleRun(" and "),
                    RedesignTitleRun("preserve?", italic: true)
                ])
            ],
            gradient: RedesignGradient.heroTitleDarkBlue
        )
    }
    .padding()
    .background(RedesignColor.whiteGray)
}
