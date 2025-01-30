//
//  OnboardingView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.03.2024.

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingContainerViewModel
    
    @State private var isBack = false
    @Environment(\.presentationMode) var presentationMode
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
                if viewModel.contentType != .none {
                    switch viewModel.contentType {
                    case .welcome:
                        OnboardingWelcomeView(viewModel: OnboardingInvitedWelcomeViewModel(containerViewModel: viewModel), buttonAction: {
                            isBack = false
                            withAnimation {
                                viewModel.contentType = .createArchive
                            }
                        })
                        .transition(AnyTransition.asymmetric(
                            insertion:.move(edge: isBack ? .leading : .trailing),
                            removal: .opacity)
                        )
                    case .pendingWelcome:
                        OnboardingInvitedWelcomeView(viewModel: OnboardingInvitedWelcomeViewModel(containerViewModel: viewModel)) {
                            isBack = false
                            withAnimation {
                                viewModel.contentType = .chartYourPath
                            }
                        } newArchiveButtonAction: {
                            isBack = false
                            withAnimation {
                                viewModel.contentType = .createArchive
                            }
                        }
                        .transition(AnyTransition.asymmetric(
                            insertion:.move(edge: isBack ? .leading : .trailing),
                            removal: .opacity)
                        )
                    case .createArchive:
                        OnboardingCreateFirstArchiveView(viewModel: OnboardingCreateFirstArchiveViewModel(containerViewModel: viewModel)) {
                            isBack = true
                            withAnimation {
                                viewModel.contentType = viewModel.firstViewContentType
                            }
                        } nextButton: {
                            isBack = false
                            withAnimation {
                                viewModel.contentType = .setArchiveName
                            }
                        }
                        .transition(AnyTransition.asymmetric(
                            insertion:.move(edge: isBack ? .leading : .trailing),
                            removal: .opacity)
                        )
                        
                    case .setArchiveName:
                        OnboardingArchiveNameView(viewModel: OnboardingArchiveNameViewModel(containerViewModel: viewModel)) {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            isBack = true
                            withAnimation {
                                viewModel.contentType = .createArchive
                            }
                        } nextButton: {
                            isBack = false
                            withAnimation {
                                viewModel.contentType = .chartYourPath
                            }
                        }
                        .transition(AnyTransition.asymmetric(
                            insertion:.move(edge: isBack ? .leading : .trailing),
                            removal: .opacity)
                        )
                    
                    case .chartYourPath:
                        OnboardingChartYourPathView(viewModel: OnboardingChartYourPathViewModel(containerViewModel: viewModel)) {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            isBack = true
                            withAnimation {
                                if viewModel.creatingNewArchive {
                                    viewModel.contentType = .setArchiveName
                                } else {
                                    viewModel.contentType = viewModel.firstViewContentType
                                }
                            }
                        } nextButton: {
                            isBack = false
                            withAnimation {
                                viewModel.contentType = .whatsImportant
                            }
                            viewModel.trackEvents(action: .skipGoals)
                        } skipButton: {
                            viewModel.trackEvents(action: .skipGoals)
                        }
                        .transition(AnyTransition.asymmetric(
                            insertion:.move(edge: isBack ? .leading : .trailing),
                            removal: .opacity)
                        )
                        
                    case .whatsImportant:
                        OnboardingWhatsImportantView(viewModel: OnboardingWhatsImportantViewModel(containerViewModel: viewModel)) {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            isBack = true
                            withAnimation {
                                viewModel.contentType = .chartYourPath
                            }
                        } nextButton: {
                            isBack = false
                            withAnimation {
                                viewModel.contentType = .congratulations
                            }
                            viewModel.trackEvents(action: .skipWhyPermanent)
                        } skipButton: {
                            viewModel.trackEvents(action: .skipWhyPermanent)
                        }
                        .transition(AnyTransition.asymmetric(
                            insertion:.move(edge: isBack ? .leading : .trailing),
                            removal: .opacity)
                        )
                        
                    case .congratulations:
                        OnboardingCongratulationsView(viewModel: OnboardingCongratulationsViewModel(containerViewModel: viewModel)) {
                            
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
                .opacity(viewModel.isLoading  ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: viewModel.isLoading)
                .allowsHitTesting(viewModel.isLoading)
        }
        .ignoresSafeArea(.all)
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Error"), message: Text("Something went wrong. Please try again later."), dismissButton: .default(Text(String.ok)) {
                viewModel.showAlert = false
            })
        }
        .onChange(of: viewModel.initIsLoading, perform: { loading in
            if !loading {
                viewModel.contentType = viewModel.allArchives.isEmpty ? .welcome : .pendingWelcome
                viewModel.firstViewContentType = viewModel.contentType
            }
        })
    }
    
    
    var topProgressBar: some View {
        HStack(spacing: Constants.Design.isPhone ? 8 : 24) {
            switch viewModel.contentType {
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
    let onboardingViewModel = OnboardingContainerViewModel(username: "none", password: "none")
    onboardingViewModel.fullName = "really long username"
    onboardingViewModel.allArchives = [
        OnboardingArchive(fullname: "Documents", accessType: "viewer", status: ArchiveVOData.Status.ok, archiveID: 33, thumbnailURL: "", isThumbnailGenerated: false),
        OnboardingArchive(fullname: "Files", accessType: "admin", status: ArchiveVOData.Status.pending, archiveID: 355, thumbnailURL: "", isThumbnailGenerated: false),
        OnboardingArchive(fullname: "Photos", accessType: "editor", status: ArchiveVOData.Status.pending, archiveID: 400, thumbnailURL: "", isThumbnailGenerated: false)
        ]
    onboardingViewModel.archiveName = "new archive"
    onboardingViewModel.contentType = .pendingWelcome
    onboardingViewModel.firstViewContentType = .pendingWelcome
    
    return ZStack {
        Color(.primary)
        OnboardingView(viewModel: onboardingViewModel)
    }
    .ignoresSafeArea()
}

enum OnboardingContentType {
    case none, welcome, pendingWelcome, createArchive, setArchiveName, chartYourPath, whatsImportant, congratulations
}
