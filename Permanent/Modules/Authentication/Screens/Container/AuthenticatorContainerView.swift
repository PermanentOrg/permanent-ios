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
    
    var body: some View {
        GeometryReader { geometry in
            let leftComponentWidth = geometry.size.width * 0.66
            ZStack {
                Gradient.darkLightBlueGradient
                    .ignoresSafeArea()
                
                VStack {
                    HStack(spacing: 0) {
                        if !Constants.Design.isPhone {
                            VStack {
                                AuthLeftSideView(viewModel: AuthLeftSideViewModel(containerViewModel: viewModel), startExploringAction: {
                                    UIApplication.shared.open(URL(string: "https://www.permanent.org/gallery")!)
                                })
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .cornerRadius(12)
                                .padding(32)
                                .padding(.leading, 32)
                            }
                            .frame(height: geometry.size.height)
                            .frame(width: leftComponentWidth)
                        }
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
                                    case .verifyIdentity:
                                        AuthVerifyIdentityView(viewModel: AuthVerifyIdentityViewModel(containerViewModel: viewModel), loginSuccess: {
                                        })
                                        .transition(AnyTransition.asymmetric(
                                            insertion: viewModel.insertionViewTransition,
                                            removal: .opacity)
                                        )
                                    case .forgotPassword:
                                        ForgotPasswordView(viewModel: ForgotPasswordViewModel(containerViewModel: viewModel)) {
                                        }
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(32)
                        .padding(.trailing, Constants.Design.isPhone ? 0 : 32)
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
    
    func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    AuthenticatorContainerView(viewModel: AuthenticatorContainerViewModel())
}
