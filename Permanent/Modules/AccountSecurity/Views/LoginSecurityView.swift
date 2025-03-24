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
    @StateObject var navigationStateManager = NavigationStateManager()
    
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
            .toolbar(.hidden, for: .navigationBar)
        }
    }
    
    var backgroundView: some View {
        Color.whiteGray
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
    }
    
    var contentView: some View {
        ZStack(alignment: .bottom) {
            if Constants.Design.isPhone {
                VStack(spacing: 10) {
                    NavigationLink {
                        ViewRepresentableContainer(viewRepresentable: PasswordUpdateViewControllerRepresentable(), title: PasswordUpdateViewControllerRepresentable().title)
                            .navigationBarBackButtonHidden(true)
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
                        .onChange(of: navigationStateManager.refreshTwoStepData) { newValue in
                            if newValue {
                                viewModel.checkTwoFactorStatus()
                                navigationStateManager.refreshTwoStepData = false
                            }
                        }
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
                .padding(.top, 10)
                .onAppear() {
                    viewModel.checkTwoFactorStatus()
                }
            } else {
                NavigationSplitView(columnVisibility: .constant(.doubleColumn)) {
                    VStack(spacing: 0) {
                        NavigationLink {
                            ViewRepresentableWithoutTitleContainer(viewRepresentable: PasswordUpdateViewControllerRepresentable())
                                .toolbar(.hidden, for: .navigationBar)
                                .padding(.vertical, Constants.Design.isPhone ? 16 : 64)
                                .padding(.horizontal, Constants.Design.isPhone ? 24 : 128)
                                .onAppear {
                                    navigationStateManager.selectionState = .changePassword
                                }
                        } label: {
                            CustomListItemView(
                                image: Image(.securityChangePass),
                                titleText: "Change password",
                                descText: "Update your password to keep your account secure.",
                                isSelected: .constant(navigationStateManager.selectionState == .changePassword)
                            )
                            .frame(height: 112)
                        }
                        Divider()
                        NavigationLink {
                            TwoStepVerificationView(
                                isTwoFactorEnabled: viewModel.isTwoStepVerificationToggleOn,
                                twoFactorMethods: viewModel.twoFactorMethods
                            )
                            .toolbar(.hidden, for: .navigationBar)
                            .navigationBarBackButtonHidden(true)
                            .onChange(of: navigationStateManager.refreshTwoStepData) { newValue in
                                if newValue {
                                    viewModel.checkTwoFactorStatus()
                                    navigationStateManager.refreshTwoStepData = false
                                }
                            }
                            .onAppear {
                                navigationStateManager.selectionState = .twoStepVerification
                            }
                        } label: {
                            CustomListItemView(
                                image: Image(.securityTwoStepVerify),
                                titleText: "Two-step verification",
                                descText: "Enhance account security by requiring a login verification code.",
                                showBadge: viewModel.twoFactorBadgeStatus != nil,
                                badgeText: viewModel.twoFactorBadgeStatus?.text ?? "",
                                badgeColor: viewModel.twoFactorBadgeStatus?.color ?? .clear,
                                isSelected: .constant(navigationStateManager.selectionState == .twoStepVerification)
                            )
                            .frame(height: 112)
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
                        .frame(height: 112)
                        Spacer()
                    }
                    .navigationSplitViewColumnWidth(min: 400, ideal: 400)
                    .onAppear() {
                        viewModel.checkTwoFactorStatus()
                    }
                    .toolbar(.hidden, for: .navigationBar)
                } detail: {
                    SecurityDetailView()
                        .toolbar(.hidden, for: .navigationBar)
                }
                .environmentObject(navigationStateManager)
            }
        }
        .navigationBarTitle("Login & Security", displayMode: .inline)
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
