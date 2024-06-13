//
//  GradientSemiCirclesLoaderView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 07.06.2024.

import SwiftUI

struct GradientSemiCirclesLoaderView: View {
    @State private var rotate = false

    var body: some View {
        ZStack {
            SemiCircle()
                .stroke(Gradient.purpleYellowGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 25, height: 25)
                .rotationEffect(.degrees(rotate ? 360 : 0))
                .animation(Animation.linear(duration: 4).repeatForever(autoreverses: false), value: rotate)
                .onAppear {
                    rotate = true
                }
            
            SemiCircle()
                .stroke(Gradient.yellowPurpleGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(rotate ? 360 : 0))
                .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false), value: rotate)
                .onAppear {
                    rotate = true
                }
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(width: 50, height: 50)
    }
}

struct SemiCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        return path
    }
}

struct ContentView: View {
    var body: some View {
        GradientSemiCirclesLoaderView()
    }
}

#Preview {
    GradientSemiCirclesLoaderView()
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .edgesIgnoringSafeArea(.all)
            GradientSemiCirclesLoaderView()
        }
    }
}
