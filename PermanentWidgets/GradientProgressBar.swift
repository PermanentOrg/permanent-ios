//
//  GradientProgressBar.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import SwiftUI

/// `GeometryReader` is deliberate: `containerRelativeFrame` is iOS 17+ and this target ships
/// to 16.2, and `ProgressView` tints with a `Color`, not a gradient. Revisit at 17.
struct GradientProgressBar: View {
    let progress: Double
    let fill: LinearGradient

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: UploadActivityStyle.barTrackRadius)
                    .fill(UploadActivityStyle.progressTrack)
                RoundedRectangle(cornerRadius: UploadActivityStyle.barFillRadius)
                    .fill(fill)
                    .frame(width: proxy.size.width * clamped)
            }
        }
        .frame(height: UploadActivityStyle.barHeight)
        .accessibilityElement()
        .accessibilityLabel("Upload progress")
        .accessibilityValue("\(Int(clamped * 100)) percent")
    }
}

#if DEBUG
#Preview("Bar across the range") {
    VStack(spacing: 20) {
        ForEach([0.0, 0.08, 0.5, 0.99, 1.0], id: \.self) { value in
            GradientProgressBar(progress: value, fill: UploadActivityStyle.progressFill)
        }
    }
    .padding()
    .frame(width: 294)
    .background(Color.black)
}
#endif
