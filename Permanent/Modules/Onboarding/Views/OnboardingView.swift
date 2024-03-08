//
//  OnboardingView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.03.2024.

import SwiftUI

struct OnboardingView: View {
    var body: some View {
        ZStack {
            Gradient.darkLightBlueGradient
            VStack {
                Text("Onboarding View")
                    .foregroundColor(.white)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    OnboardingView()
}
