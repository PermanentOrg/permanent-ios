//
//  RedesignSkeletonView.swift
//  Permanent
//
//  Frame A loading skeleton: avatar + title/subtitle bars + two large cards,
//  with a shimmer sweeping left→right over the neutral gray shapes.
//  Built from native shapes only (no PNG).
//

import SwiftUI

struct RedesignSkeletonView: View {
    @State private var shimmerX: CGFloat = -1

    private let neutral = RedesignColor.skeletonAvatar

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Avatar row: 40×40 avatar + title (96×20 r10) + subtitle (184×12 r6).
            HStack(alignment: .top, spacing: 16) {
                Circle()
                    .fill(neutral)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(neutral)
                        .frame(width: 96, height: 20)
                        .padding(.top, 2)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(neutral)
                        .frame(width: 184, height: 12)
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 32) // pushes first card to ~y72 below the row

            // Card 1: full width × ~400, radius 24, subtle vertical gradient.
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(RedesignGradient.skeletonCard)
                .frame(height: 400)
                .padding(.bottom, 24)

            // Card 2: identical, fades at the bottom of the screen.
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(RedesignGradient.skeletonCard)
                .frame(height: 400)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Shimmer: a moving translucent white band masked to the skeleton itself.
        .overlay(shimmerOverlay.allowsHitTesting(false))
        .mask(skeletonMask)
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                shimmerX = 2
            }
        }
    }

    /// White diagonal sweep used as the moving highlight.
    private var shimmerOverlay: some View {
        GeometryReader { geo in
            let width = geo.size.width
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0), location: 0.35),
                    .init(color: .white.opacity(0.6), location: 0.5),
                    .init(color: .white.opacity(0), location: 0.65)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width)
            .offset(x: shimmerX * width)
        }
    }

    /// The skeleton geometry reused as the mask so the shimmer only shows on shapes.
    private var skeletonMask: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                Circle().frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 10).frame(width: 96, height: 20).padding(.top, 2)
                    RoundedRectangle(cornerRadius: 6).frame(width: 184, height: 12)
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 32)
            RoundedRectangle(cornerRadius: 24).frame(height: 400).padding(.bottom, 24)
            RoundedRectangle(cornerRadius: 24).frame(height: 400)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    RedesignSkeletonView()
        .padding(24)
        .background(RedesignColor.whiteGray)
}
