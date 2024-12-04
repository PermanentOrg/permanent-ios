//
//  LoginSecurityView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 19.11.2024.

import SwiftUI

struct LoginSecurityView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: LoginSecurityViewModel
    @State private var navigateToTwoStep = false
    
    init(viewModel: StateObject<LoginSecurityViewModel>) {
        self._viewModel = viewModel
    }
    
    var dismissAction: ((Bool) -> Void)?
    
    var body: some View {
        ZStack {
            CustomNavigationView {
                ZStack {
                    backgroundView
                    contentView
                }
                .ignoresSafeArea(.all)
            } leftButton: {
                backButton
            } rightButton: {
                EmptyView()
            }
        }
    }
    
    var backgroundView: some View {
        Color.whiteGray
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
    }
    
    var contentView: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 10) {
                Button {
                    viewModel.addStorageIsPresented = true
                } label: {
                    CustomListItemView(
                        image: Image(.securityChangePass),
                        titleText: "Change password",
                        descText: "Update your password to keep your account secure."
                    )
                }
                Divider()
                NavigationLink {
                    TwoStepVerificationView(
                        isTwoFactorEnabled: viewModel.isTwoStepVerificationToggleOn,
                        twoFactorMethods: viewModel.twoFactorMethods
                    )
                    .navigationBarBackButtonHidden(true)
                } label: {
                    CustomListItemView(
                        image: Image(.securityTwoStepVerify),
                        titleText: "Two-step verification",
                        descText: "Enhance account security by requiring a login verification code.",
                        showBadge: viewModel.twoFactorBadgeStatus != nil,
                        badgeText: viewModel.twoFactorBadgeStatus?.text ?? "",
                        badgeColor: viewModel.twoFactorBadgeStatus?.color ?? .clear
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.twoFactorBadgeStatus)
                }
                Divider()
                CustomListItemView(
                    image: Image(.securityFaceId),
                    titleText: "Sign in with \(viewModel.getAuthTypeText())",
                    descText: "This option lets you securely sign in with just a glance.",
                    showToggle: true,
                    isToggleOn: $viewModel.isSecurityToggleOn
                )
                Spacer()
            }
        }
        .navigationBarTitle("Login & Security", displayMode: .inline)
        .padding(.top, 10)
        .onChange(of: viewModel.isSecurityToggleOn) { newValue in
            viewModel.updateBiometricsStatus(isEnabled: newValue)
        }
    }
    
    var backButton: some View {
        Button(action: {
            dismissView()
        }) {
            HStack {
                Image(.settingsNavigationBarBackIcon)
                    .foregroundColor(.white)
            }
        }
    }
    
    func dismissView() {
        dismissAction?(false)
        presentationMode.wrappedValue.dismiss()
    }
}
