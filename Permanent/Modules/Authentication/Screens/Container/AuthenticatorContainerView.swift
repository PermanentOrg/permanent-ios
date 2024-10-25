//
//  AuthenticatorContainerView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.09.2024.

import SwiftUI

struct AuthenticatorContainerView: View {
    @ObservedObject var viewModel: AuthenticatorContainerViewModel
    
    @State private var isGoingBack = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Gradient.darkLightBlueGradient
                    .ignoresSafeArea()
                
                VStack {
                    if horizontalSizeClass == .compact {
                        // Only show the right column for compact screens (iPhones)
                        rightColumnView()
                            .frame(maxWidth: .infinity)
                            .padding(32)
                    } else {
                        // Show both columns for regular screens (iPads)
                        HStack(spacing: 0) {
                            leftColumnView()
                                .frame(maxWidth: geometry.size.width * 0.70)
                                .frame(height: geometry.size.height)
                            
                            rightColumnView()
                                .frame(width: geometry.size.width * 0.30)
                                .frame(maxHeight: .infinity)
                                .padding(EdgeInsets(top: 32, leading: 32, bottom: 32, trailing: 64))
                        }
                    }
                }
                LoadingOverlay()
                    .opacity(viewModel.isLoading  ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: viewModel.isLoading)
                    .allowsHitTesting(viewModel.isLoading)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: viewModel.contentType) { newValue in
            viewModel.showErrorBanner = false
        }
    }
    
    @ViewBuilder
    private func leftColumnView() -> some View {
        VStack {
            AuthLeftSideView(viewModel: AuthLeftSideViewModel(containerViewModel: viewModel), startExploringAction: {
                UIApplication.shared.open(URL(string: "https://www.permanent.org/gallery")!)
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(12)
            .padding(32)
            .padding(.leading, 32)
        }
    }

    @ViewBuilder
    private func rightColumnView() -> some View {
        ZStack {
            VStack {
                if viewModel.contentType != .none {
                    switch viewModel.contentType {
                    case .login:
                        LoginView(viewModel: LoginViewModel(containerViewModel: viewModel), loginSuccess: {
                            dismissView()
                        })
                        .transition(AnyTransition.asymmetric(
                            insertion: viewModel.insertionViewTransition,
                            removal: .opacity)
                        )
                    case .register:
                        RegisterView(viewModel: RegisterViewModel(containerViewModel: viewModel), loginSuccess: {
                            dismissView()
                        })
                        .transition(AnyTransition.asymmetric(
                            insertion: viewModel.insertionViewTransition,
                            removal: .opacity)
                        )
                    case .verifyIdentity:
                        AuthVerifyIdentityView(viewModel: AuthVerifyIdentityViewModel(containerViewModel: viewModel), loginSuccess: {})
                            .transition(AnyTransition.asymmetric(
                                insertion: viewModel.insertionViewTransition,
                                removal: .opacity)
                            )
                    case .forgotPassword:
                        ForgotPasswordView(viewModel: ForgotPasswordViewModel(containerViewModel: viewModel)) {}
                            .transition(AnyTransition.asymmetric(
                                insertion: viewModel.insertionViewTransition,
                                removal: .opacity)
                            )
                    case .forgotPasswordConfirmation:
                        ForgotPasswordConfimationView(viewModel: viewModel)
                            .transition(AnyTransition.asymmetric(
                                insertion: viewModel.insertionViewTransition,
                                removal: .opacity)
                            )
                    default:
                        Spacer()
                    }
                }
            }
            AuthBannerView(message: viewModel.bannerErrorMessage, isVisible: $viewModel.showErrorBanner)
                .padding(.bottom, Constants.Design.isPhone ? -32 : -64)
                .ignoresSafeArea()
        }
    }
    
    func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    AuthenticatorContainerView(viewModel: AuthenticatorContainerViewModel())
}
