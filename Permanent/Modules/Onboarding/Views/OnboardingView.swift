//
//  OnboardingView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.03.2024.

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var onboardingValues = OnboardingArchiveViewModel(username: "", password: "")
    @State private var isBack = false
    @State private var contentType: ContentType = .none
    @Environment(\.presentationMode) var presentationMode
    
    enum ContentType {
        case none, welcome, pendingWelcome, createArchive, setArchiveName, chartYourPath, whatsImportant, congratulations
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
                        OnboardingWelcomeView(onboardingStorageValues: onboardingValues) {
                            isBack = false
                            withAnimation {
                                contentType = .createArchive
                            }
                        }
                        .transition(AnyTransition.asymmetric(
                            insertion:.move(edge: isBack ? .leading : .trailing),
                            removal: .opacity)
                        )
                    case .pendingWelcome:
                        OnboardingInvitedWelcomeView(onboardingStorageValues: onboardingValues) {
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
                            onboardingValues.finishOnboard(_:) { response in
                                if response == .success {
                                    isBack = false
                                    withAnimation {
                                        contentType = .congratulations
                                    }
                                }
                            }
                        } skipButton: {
                            
                        }
                        .transition(AnyTransition.asymmetric(
                            insertion:.move(edge: isBack ? .leading : .trailing),
                            removal: .opacity)
                        )
                        
                    case .congratulations:
                        OnboardingCongratulationsView(onboardingValues: onboardingValues) {
                            
                        } nextButton: {
                            AppDelegate.shared.rootViewController.setDrawerRoot()
                            dismissView()
                        }

                    default:
                        Spacer()
                    }
                }
                Spacer()
            }
            .padding(.horizontal, Constants.Design.isPhone ? 32 : 64)
            .padding(.top, Constants.Design.isPhone ? 70 : 48)
            LoadingOverlay()
                .opacity(onboardingValues.isLoading  ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: onboardingValues.isLoading)
                .allowsHitTesting(onboardingValues.isLoading)
        }
        .ignoresSafeArea(.all)
        .alert(isPresented: $onboardingValues.showAlert) {
            Alert(title: Text("Error"), message: Text("Something went wrong. Please try again later."), dismissButton: .default(Text(String.ok)) {
                onboardingValues.showAlert = false
            })
        }
        .onAppear(perform: {
            contentType = onboardingValues.allArchives.isEmpty ? .welcome : .pendingWelcome
        })
    }
    
    
    var topProgressBar: some View {
        HStack(spacing: Constants.Design.isPhone ? 8 : 24) {
            switch contentType {
            case .none:
                DividerSmallBarView(type: .empty)
                DividerSmallBarView(type: .empty)
                DividerSmallBarView(type: .empty)
                
            case .welcome:
                DividerSmallBarView(type: .gradient)
                DividerSmallBarView(type: .empty)
                DividerSmallBarView(type: .empty)
                
            case .pendingWelcome:
                DividerSmallBarView(type: .gradient)
                DividerSmallBarView(type: .empty)
                DividerSmallBarView(type: .empty)
                
            case .createArchive, .setArchiveName:
                DividerSmallBarView(type: .gradient)
                DividerSmallBarView(type: .empty)
                DividerSmallBarView(type: .empty)
                
            case .chartYourPath:
                DividerSmallBarView(type: .empty)
                DividerSmallBarView(type: .gradient)
                DividerSmallBarView(type: .empty)
                
            case .whatsImportant:
                DividerSmallBarView(type: .empty)
                DividerSmallBarView(type: .empty)
                DividerSmallBarView(type: .gradient)
            
            case .congratulations:
                DividerSmallBarView(type: .empty)
                DividerSmallBarView(type: .empty)
                DividerSmallBarView(type: .gradient)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 32)
        
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    var onboardingViewModel = OnboardingArchiveViewModel(username: "none", password: "none")
    onboardingViewModel.fullName = "long username name name"
    onboardingViewModel.allArchives = [
        OnboardingInvitedArchives(fullname: "Documents", accessType: "viewer", status: ArchiveVOData.Status.ok, archiveID: 33),
        OnboardingInvitedArchives(fullname: "Files", accessType: "admin", status: ArchiveVOData.Status.pending, archiveID: 355),
        OnboardingInvitedArchives(fullname: "Photos", accessType: "editor", status: ArchiveVOData.Status.pending, archiveID: 400)
        ]
    onboardingViewModel.archiveName = "new archive"
    
    return ZStack {
        Color(.primary)
        OnboardingView(onboardingValues: onboardingViewModel)
    }
    .ignoresSafeArea()
}
