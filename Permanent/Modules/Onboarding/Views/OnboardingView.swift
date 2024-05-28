//
//  OnboardingView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.03.2024.

import SwiftUI

struct OnboardingView: View {
    @StateObject var onboardingValues = OnboardingStorageValues()
    @State private var isBack = false
    @State private var contentType: ContentType = .welcome
    
    enum ContentType {
        case none, welcome, createArchive, setArchiveName, chartYourPath, whatsImportant
    }
    
    @State var bottomButtonsPadding: CGFloat =  40

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
                .onTapGesture {
                    dismissKeyboard()
                }
                topProgressBar
                    .onTapGesture {
                        dismissKeyboard()
                    }
                if contentType != .none {
                    switch contentType {
                    case .welcome:
                        OnboardingWelcomeView {
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
                        OnboardingCreateFirstArchiveView(onboardingValues: onboardingValues) {
                            isBack = true
                            withAnimation {
                                contentType = .welcome
                            }
                            
                        } nextButton: {
                            isBack = false
                            withAnimation {
                                contentType = .setArchiveName
                            }
                        }
                        .transition(AnyTransition.asymmetric(
                            insertion:.move(edge: isBack ? .leading : .trailing),
                            removal: .opacity)
                        )
                        
                    case .setArchiveName:
                        OnboardingArchiveName(onboardingValues: onboardingValues) {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            isBack = true
                            withAnimation {
                                contentType = .createArchive
                            }
                        } nextButton: {
                            isBack = false
                            withAnimation {
                                contentType = .chartYourPath
                            }
                        }
                        .transition(AnyTransition.asymmetric(
                            insertion:.move(edge: isBack ? .leading : .trailing),
                            removal: .opacity)
                        )
                    
                    case .chartYourPath:
                        OnboardingChartYourPathView(onboardingValues: onboardingValues) {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            isBack = true
                            withAnimation {
                                contentType = .setArchiveName
                            }
                        } nextButton: {
                            isBack = false
                            withAnimation {
                                contentType = .whatsImportant
                            }
                        } skipButton: {
                            
                        }
                        .transition(AnyTransition.asymmetric(
                            insertion:.move(edge: isBack ? .leading : .trailing),
                            removal: .opacity)
                        )
                        
                    case .whatsImportant:
                        OnboardingWhatsImportantView(onboardingValues: onboardingValues) {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            isBack = true
                            withAnimation {
                                contentType = .chartYourPath
                            }
                        } nextButton: {
                            
                        } skipButton: {
                            
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
            .padding(.horizontal, Constants.Design.isPhone ? 32 : 64)
            .padding(.top, Constants.Design.isPhone ? 70 : 48)
        }
        .ignoresSafeArea(.all)
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
                
            case .createArchive, .setArchiveName:
                DividerSmallBarView(type: .gradient)
                DividerSmallBarView(type: .empty)
                DividerSmallBarView(type: .empty)
                
            case .chartYourPath:
                DividerSmallBarView(type: .gradient)
                DividerSmallBarView(type: .gradient)
                DividerSmallBarView(type: .empty)
                
            case .whatsImportant:
                DividerSmallBarView(type: .gradient)
                DividerSmallBarView(type: .gradient)
                DividerSmallBarView(type: .gradient)
                
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 32)
        
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
