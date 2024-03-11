//
//  OnboardingView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.03.2024.

import SwiftUI

struct OnboardingView: View {
    enum ContentType {
        case none, welcome
    }
    
    @State private var contentType: ContentType = .welcome
    
    var body: some View {
        ZStack {
            Gradient.darkLightBlueGradient
            VStack() {
                HStack() {
                    Image(.simpleLogo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 30)
                        .clipped()
                    Spacer()
                }
                HStack(spacing: 8) {
                    DividerSmallBar(type: .gradient)
                    DividerSmallBar(type: .empty)
                    DividerSmallBar(type: .empty)
                }
                .padding(.top, 24)
                .padding(.bottom, 32)
                
                if contentType != .none {
                    switch contentType {
                    case .welcome:
                        OnboardingWelcomeView()
                    default:
                        Spacer()
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 70)
            .padding(.bottom, 40)
        }
        .ignoresSafeArea()
    }
}
