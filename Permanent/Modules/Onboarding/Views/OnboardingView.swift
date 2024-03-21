//
//  OnboardingView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.03.2024.

import SwiftUI

struct OnboardingView: View {
    var fullName: String =  AuthenticationManager.shared.session?.account.fullName ?? ""
    @State private var isBack = false
    
    enum ContentType {
        case none, welcome, createArchive
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
                topProgressBar
                Group {
                    if contentType != .none {
                        switch contentType {
                        case .welcome:
                            OnboardingWelcomeView(fullName: fullName) {
                                isBack = false
                                withAnimation {
                                    contentType = .createArchive
                                }
                            }
                            .transition(AnyTransition.asymmetric(
                                insertion:.move(edge: isBack ? .leading : .trailing),
                                removal: .opacity)
                            )
                        case .createArchive:
                            OnboardingCreateFirstArchiveView {
                                isBack = true
                                withAnimation {
                                    contentType = .welcome
                                }
                                
                            } nextButton: {
                                
                            }
                            .transition(AnyTransition.asymmetric(
                                insertion:.move(edge: isBack ? .leading : .trailing),
                                removal: .opacity)
                            )
                            
                        default:
                            Spacer()
                        }
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, Constants.Design.isPhone ? 32 : 64)
            .padding(.top, Constants.Design.isPhone ? 70 : 48)
            .padding(.bottom, 40)
        }
        .ignoresSafeArea()
    }
    
    var topProgressBar: some View {
        HStack(spacing: 8) {
            switch contentType {
            case .none:
                DividerSmallBarView(type: .empty)
                DividerSmallBarView(type: .empty)
                DividerSmallBarView(type: .empty)
            case .welcome:
                DividerSmallBarView(type: .empty)
                DividerSmallBarView(type: .empty)
                DividerSmallBarView(type: .empty)
            case .createArchive:
                DividerSmallBarView(type: .gradient)
                DividerSmallBarView(type: .empty)
                DividerSmallBarView(type: .empty)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 32)
        
    }
}
