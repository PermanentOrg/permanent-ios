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
            ZStack {
                Gradient.darkLightBlueGradient
                HStack(spacing: 0) {
                    if !Constants.Design.isPhone {
                        AuthLeftSideView(viewModel: AuthLeftSideViewModel(containerViewModel: viewModel), startExploringAction: {
                            UIApplication.shared.open(URL(string: "https://www.permanent.org/gallery")!)
                        })
                            .frame(width: geometry.size.width * 0.58)
                            .cornerRadius(12)
                            .padding(.vertical, 64)
                            .padding(.leading, 64)
                    }
                    
                    if viewModel.contentType != .none {
                        switch viewModel.contentType {
                        case .login:
                            LoginView(viewModel: LoginViewModel(containerViewModel: viewModel), loginSuccess: {
                                dismissView()
                            })
                        case .verifyIdentity:
                            AuthVerifyIdentityView(viewModel: AuthVerifyIdentityViewModel(containerViewModel: viewModel), loginSuccess: {
                            })
                        default:
                            Spacer()
                        }
                    }
                }
                LoadingOverlay()
                    .opacity(viewModel.isLoading  ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: viewModel.isLoading)
                    .allowsHitTesting(viewModel.isLoading)
            }
        }
        .ignoresSafeArea(.all)
    }
    
    func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    AuthenticatorContainerView(viewModel: AuthenticatorContainerViewModel())
}
