//
//  TwoStepVerificationView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.11.2024.


import SwiftUI

struct TwoStepVerificationView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var navigationStateManager: NavigationStateManager
    @StateObject var viewModel: TwoStepVerificationViewModel
    @State var showDeleteAlert: Bool = false
    @State var showDeleteModal: Bool = false
    @State var changeAuthMethodAlert: Bool = false
    @State var changeAuthMethodModal: Bool = false
    
    init(isTwoFactorEnabled: Bool = false, twoFactorMethods: [TwoFactorMethod]) {
        self._viewModel = StateObject(wrappedValue: TwoStepVerificationViewModel(isTwoFactorEnabled: isTwoFactorEnabled, twoFactorMethods: twoFactorMethods))
    }
    
    var body: some View {
        ZStack {
            if Constants.Design.isPhone {
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
            } else {
                ZStack {
                    backgroundView
                    contentView
                        .padding(.vertical, 64)
                        .padding(.horizontal, 128)
                }
                .ignoresSafeArea(.all)
            }
            BottomNotificationWithOverlayView(message: viewModel.bottomBannerMessage, isVisible: $viewModel.showBottomBanner)
                .padding(.horizontal, 32)
            DeleteBottomAlertView(showErrorMessage: $showDeleteAlert, deleteMethodConfirmed: $viewModel.deleteMethodConfirmed, twoFactorMethod: viewModel.methodSelectedForDelete)
            ChangeAuthMethodBottomAlertView(showErrorMessage: $changeAuthMethodAlert, deleteMethodConfirmed: $viewModel.changeMethodConfirmed, twoFactorMethod: viewModel.methodSelectedForDelete)
        }
        .onAppear() {
            if viewModel.deleteMethodConfirmed != nil {
                viewModel.deleteMethodConfirmed = nil
            }
            
            if viewModel.changeMethodConfirmed != nil {
                viewModel.changeMethodConfirmed = nil
            }
            
            if viewModel.methodSelectedForDelete != nil {
                viewModel.methodSelectedForDelete = nil
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
            VStack(alignment: .leading, spacing: Constants.Design.isPhone ? 24 : 32) {
                if Constants.Design.isPhone {
                    bannerTwoStepVerificationView
                } else {
                    Text("Two-step verification")
                        .font(.custom(FontName.usualMedium.rawValue, fixedSize: 24))
                        .foregroundColor(.blue900)
                        .padding(.bottom, 32)
                    bannerTwoStepVerificationView
                        .cornerRadius(12)
                }
                
                descriptionView
                
                if viewModel.isTwoFactorEnabled {
                    verificationMethodsView
                }
                if viewModel.twoFactorMethods.count < 2 {
                    RoundButtonUsualFontView(isDisabled: false, isLoading: false, text: viewModel.twoFactorMethods.isEmpty ? "Add two-step verification method" : "Change verification method") {
                        if viewModel.isTwoFactorEnabled {
                            viewModel.methodSelectedForDelete = viewModel.twoFactorMethods.first
                            withAnimation {
                                if Constants.Design.isPhone {
                                    changeAuthMethodAlert = true
                                } else {
                                    changeAuthMethodModal = true
                                }
                            }
                        } else {
                            viewModel.checkVerificationMethod = true
                        }
                    }
                    .padding(.horizontal, Constants.Design.isPhone ? 24 : 0)
                }
                
                Spacer()
            }
            
            if viewModel.twoFactorMethods.count > 0 {
                VStack(spacing: 24) {
                    Divider()
                    Text("To disable two-step verification, you must remove all existing two-step verification methods you have previously added.")
                        .textStyle(UsualSmallXLightTextStyle())
                        .lineSpacing(6)
                        .foregroundColor(Color(red: 0.26, green: 0.29, blue: 0.43))
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, Constants.Design.isPhone ? 24 : 0)
                .padding(.bottom, 32)
            }
        }
        .onChange(of: viewModel.refreshAccountDataRequired, perform: { newValue in
            if newValue {
                viewModel.refreshAccountData()
                if !Constants.Design.isPhone {
                    navigationStateManager.refreshTwoStepData = true
                }
            }
        })
        .onChange(of: viewModel.deleteMethodConfirmed, perform: { newValue in
            if let _ = newValue {
                viewModel.changeAuthFlow = false
                viewModel.checkVerificationMethod = true
            }
        })
        .onChange(of: viewModel.changeMethodConfirmed, perform: { newValue in
            if let _ = newValue {
                viewModel.changeAuthFlow = true
                viewModel.checkVerificationMethod = true
            }
        })
        .onChange(of: viewModel.bottomBannerMessage, perform: { newValue in
            if newValue != .none {
                if viewModel.showError == false {
                    viewModel.methodSelectedForDelete = nil
                    viewModel.deleteMethodConfirmed = nil
                    viewModel.changeMethodConfirmed = nil
                    viewModel.displayBannerWithAutoClose()
                }
            } else {
                viewModel.showBottomBanner = false
            }
        })
        .navigationBarTitle("Two-step verification", displayMode: .inline)
        .sheet(isPresented: $viewModel.checkVerificationMethod) {
            TwoStepConfirmationContainerView(viewModel: TwoStepConfirmationContainerViewModel(refreshSecurityView: $viewModel.refreshAccountDataRequired, methodSelectedForDelete: viewModel.changeAuthFlow ? $viewModel.changeMethodConfirmed : $viewModel.deleteMethodConfirmed, twoStepVerificationBottomBannerMessage: $viewModel.bottomBannerMessage, changingAuthFlow: viewModel.changeAuthFlow))
        }
        .sheet(isPresented: $showDeleteModal) {
            TwoStepTabletModalAlertView(showErrorMessage: $showDeleteModal, deleteMethodConfirmed: $viewModel.deleteMethodConfirmed, twoFactorMethod: viewModel.methodSelectedForDelete, deleteMessage: true)
                .presentationDetents([.height(250)])
        }
        .sheet(isPresented: $changeAuthMethodModal) {
            TwoStepTabletModalAlertView(showErrorMessage: $changeAuthMethodModal, deleteMethodConfirmed: $viewModel.changeMethodConfirmed, twoFactorMethod: viewModel.methodSelectedForDelete, deleteMessage: false)
                .presentationDetents([.height(300)])
        }
    }
    
    var bannerTwoStepVerificationView: some View {
        BannerTwoStepVerificationView(isEnabled: viewModel.isTwoFactorEnabled)
    }
    
    var descriptionView: some View {
        Text("Enhance account security by requiring a login verification code.")
            .textStyle(UsualRegularMediumTextStyle())
            .multilineTextAlignment(.leading)
            .foregroundColor(.blue900)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Constants.Design.isPhone ? 24 : 0)
    }
    
    var verificationMethodsView: some View {
            VStack(spacing: 16) {
                ForEach(viewModel.twoFactorMethods) { method in
                        HStack {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("\(method.type.displayName)")
                                        .textStyle(UsualSmallXSemiBoldTextStyle())
                                        .foregroundColor(.blue900)
                                    
                                    if method.type == .sms {
                                            SimpleTagView(text: "DEFAULT")
                                    }
                                    
                                    Spacer()
                                    Button {
                                        viewModel.methodSelectedForDelete = method
                                        withAnimation {
                                            if Constants.Design.isPhone {
                                                showDeleteAlert = true
                                            } else {
                                                showDeleteModal = true
                                            }
                                        }
                                    } label: {
                                        Image(.twoStepDeleteIcon)
                                            .frame(width: 16, height: 16)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                HStack {
                                    Text("\(method.value)")
                                        .textStyle(UsualSmallXRegularTextStyle())
                                        .foregroundColor(Color(red: 0.35, green: 0.37, blue: 0.5))

                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 48)
                        .padding(24)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .inset(by: 0.5)
                                .stroke(Color(red: 0.91, green: 0.91, blue: 0.93), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, Constants.Design.isPhone ? 24 : 0)
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
        presentationMode.wrappedValue.dismiss()
    }
}

