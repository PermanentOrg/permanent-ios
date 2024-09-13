//
//  AuthenticatorContainerView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.09.2024.

import SwiftUI

struct AuthenticatorContainerView: View {
    @ObservedObject var viewModel: AuthenticatorContainerViewModel
    
    @State private var isBack = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Gradient.darkLightBlueGradient
                HStack(spacing: 0) {
                    if !Constants.Design.isPhone {
                        AuthLeftSideView()
                            .frame(width: (geometry.size.width / 3) * 2)
                    }
                    LoginView(viewModel: LoginViewModel(containerViewModel: viewModel), loginSuccess: {
                        dismissView()
                    })
                        .frame(maxWidth: .infinity)
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
