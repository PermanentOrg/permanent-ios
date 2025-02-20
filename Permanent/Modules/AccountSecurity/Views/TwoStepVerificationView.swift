//
//  TwoStepVerificationView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.11.2024.


import SwiftUI

struct TwoStepVerificationView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: TwoStepVerificationViewModel
    @State var showDeleteAlert: Bool = false
    
    init(isTwoFactorEnabled: Bool = false, twoFactorMethods: [TwoFactorMethod]) {
        self._viewModel = StateObject(wrappedValue: TwoStepVerificationViewModel(isTwoFactorEnabled: isTwoFactorEnabled, twoFactorMethods: twoFactorMethods))
    }
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
            TwoStepBottomNotificationView(message: viewModel.bottomBannerMessage, isVisible: $viewModel.showBottomBanner)
                .padding(.horizontal, 32)
            DeleteBottomAlertView(showErrorMessage: $showDeleteAlert, deleteMethodConfirmed: $viewModel.deleteMethodConfirmed, twoFactorMethod: viewModel.methodSelectedForDelete)
        }
        .onAppear() {
            if viewModel.deleteMethodConfirmed != nil {
                viewModel.deleteMethodConfirmed = nil
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
            VStack(spacing: 24) {
                bannerTwoStepVerificationView
                
                descriptionView
                
                if viewModel.isTwoFactorEnabled {
                    verificationMethodsView
                }
                if viewModel.twoFactorMethods.count < 2 {
                    RoundButtonUsualFontView(isDisabled: false, isLoading: false, text: viewModel.twoFactorMethods.isEmpty ? "Add two-step verification method" : "Change verification method") {
                        viewModel.checkVerificationMethod = true
                    }
                    .padding(.horizontal, 24)
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
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onChange(of: viewModel.refreshAccountDataRequired, perform: { newValue in
            if newValue {
                viewModel.refreshAccountData()
            }
        })
        .onChange(of: viewModel.deleteMethodConfirmed, perform: { newValue in
            if let _ = newValue {
                viewModel.checkVerificationMethod = true
            }
        })
        .onChange(of: viewModel.bottomBannerMessage, perform: { newValue in
            if newValue != .none {
                if viewModel.showError == false {
                    viewModel.methodSelectedForDelete = nil
                    viewModel.deleteMethodConfirmed = nil
                    viewModel.displayBannerWithAutoClose()
                }
            } else {
                viewModel.showBottomBanner = false
            }
        })
        .navigationBarTitle("Two-step verification", displayMode: .inline)
        .sheet(isPresented: $viewModel.checkVerificationMethod) {
            TwoStepConfirmationContainerView(viewModel: TwoStepConfirmationContainerViewModel(refreshSecurityView: $viewModel.refreshAccountDataRequired, methodSelectedForDelete: $viewModel.methodSelectedForDelete, twoStepVerificationBottomBannerMessage: $viewModel.bottomBannerMessage))
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
            .padding(.horizontal, 24)
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
                                            showDeleteAlert = true
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
            .padding(.horizontal, 24)
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

