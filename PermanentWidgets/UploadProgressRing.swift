//
//  UploadProgressRing.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import SwiftUI

/// A trimmed `Circle` rather than the exported asset, which is frozen at whatever percentage
/// it was drawn at. Starts at 12 o'clock, clockwise, as the design does.
struct UploadProgressRing: View {
    /// Ring geometry is not proportional between the two sizes — the design uses a
    /// thicker stroke and a tighter inset at 36pt — so both are spelled out.
    struct Metrics {
        /// Outer box the ring sits in.
        let boxSize: CGFloat
        /// Diameter of the stroked path itself; the stroke straddles it.
        let pathDiameter: CGFloat
        let lineWidth: CGFloat

        var inset: CGFloat { (boxSize - pathDiameter) / 2 }

        /// Collapsed island: 8.5pt radius, 3pt stroke, in a 23pt box.
        static let compact = Metrics(boxSize: 23, pathDiameter: 17, lineWidth: 3)
        /// Expanded island at minimum height: 12pt radius, 4pt stroke, in a 36pt box.
        static let pill = Metrics(boxSize: 36, pathDiameter: 24, lineWidth: 4)
    }

    let progress: Double
    let metrics: Metrics
    var tint: LinearGradient = UploadActivityStyle.brandOrange
    /// SF Symbol naming the state, where the arc alone is ambiguous — a paused arc looks like a
    /// running one. `nil` while uploading, where the motion says it.
    var glyph: String?

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.24), lineWidth: metrics.lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(tint, style: StrokeStyle(lineWidth: metrics.lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .overlay {
            if let glyph {
                Image(systemName: glyph)
                    .font(.system(size: metrics.pathDiameter * 0.46, weight: .bold))
                    .foregroundStyle(UploadActivityStyle.primaryLabel)
            }
        }
        .padding(metrics.inset)
        .frame(width: metrics.boxSize, height: metrics.boxSize)
        .accessibilityElement()
        .accessibilityLabel("Upload progress")
        .accessibilityValue("\(Int(clamped * 100)) percent")
    }
}

#if DEBUG
#Preview("Ring at both sizes, across the range, with and without a glyph") {
    VStack(spacing: 20) {
        ForEach([0.0, 0.25, 0.5, 0.667, 1.0], id: \.self) { value in
            HStack(spacing: 20) {
                UploadProgressRing(progress: value, metrics: .compact)
                UploadProgressRing(progress: value, metrics: .pill)
                UploadProgressRing(progress: value, metrics: .compact, glyph: "pause.fill")
                UploadProgressRing(progress: value, metrics: .pill, glyph: "pause.fill")
            }
        }
    }
    .padding()
    .background(Color.black)
}
#endif
