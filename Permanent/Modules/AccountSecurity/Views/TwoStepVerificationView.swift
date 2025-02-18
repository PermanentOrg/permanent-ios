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
            DeleteBottomAlertView(showErrorMessage: $showDeleteAlert, deleteConfirmed: $viewModel.checkVerificationMethod, twoFactorMethod: viewModel.methodSelectedForDelete)
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
        .navigationBarTitle("Two-step verification", displayMode: .inline)
        .sheet(isPresented: $viewModel.checkVerificationMethod) {
            TwoStepConfirmationContainerView(viewModel: TwoStepConfirmationContainerViewModel(refreshSecurityView: $viewModel.refreshAccountDataRequired))
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

struct DeleteBottomAlertView: View {
    @Binding var showErrorMessage: Bool
    @Binding var deleteConfirmed: Bool
    var twoFactorMethod: TwoFactorMethod?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if showErrorMessage {
                Color.blue700
                    .opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showErrorMessage = false
                        }
                    }
                
                ZStack {
                    VStack {
                        HStack {
                            Text("Are you sure you want to delete your ") +
                            Text("\(twoFactorMethod?.type.displayName ?? "")").bold() +
                            Text(" two-step verification method?")
                        }
                        .font(.custom("Usual-Regular", size: 14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.blue700)
                        .padding(.top, 32)
                        .padding(.horizontal, 32)
                        
                        VStack(spacing: 16) {
                            Button(action: {
                                if #available(iOS 17.0, *) {
                                    withAnimation {
                                        showErrorMessage = false
                                    } completion: {
                                        deleteConfirmed = true
                                    }
                                } else {
                                    withAnimation {
                                        showErrorMessage = false
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        deleteConfirmed = true
                                    }
                                }
                            }, label: {
                                HStack {
                                    Spacer()
                                    Text("Delete")
                                        .fontWeight(.medium)
                                        .font(.custom("Usual-Regular", size: 14))
                                        .foregroundColor(Color(.white))
                                    Spacer()
                                       
                                }
                                .padding(16)
                                .frame(height: 56)
                                .background(Color.error500)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.07), radius: 40, x: 0, y: 5)
                                .frame(maxWidth: .infinity)
                            })
                            Button(action: {
                                withAnimation {
                                    showErrorMessage = false
                                }
                                
                                
                            }, label: {
                                HStack {
                                    Spacer()
                                    Text("Cancel")
                                        .font(.custom("Usual-Regular", size: 14))
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(.blue900))
                                    Spacer()
                                }
                                .padding(16)
                                .frame(height: 56)
                                .background(Color.blue50)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.07), radius: 40, x: 0, y: 5)
                                .frame(maxWidth: .infinity)

                            })
                        }
                        .padding(32)
                        
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color(.white))
                .cornerRadius(12)
                .padding(.horizontal, 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea()
    }
}
