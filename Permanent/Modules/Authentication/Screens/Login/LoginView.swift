//
//  LoginView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.09.2024.

import SwiftUI

struct LoginView: View {
    @StateObject var viewModel: LoginViewModel
    @State var showEmptySpace: Bool = true
    @FocusState var focusedField: LoginFocusField?
    @State var keyboardOpenend: Bool = false
    
    var loginSuccess: (() -> Void)
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack(spacing: 32) {
                    if geometry.size.height > 680 {
                        HStack() {
                            Image(.authLogo)
                                .frame(height: Constants.Design.isPhone ? 32 : 64)
                            Spacer()
                        }
                    } else if showEmptySpace {
                        HStack() {
                            Image(.authLogo)
                                .frame(height: Constants.Design.isPhone ? 32 : 64)
                            Spacer()
                        }
                    }
                    HStack() {
                        if Constants.Design.isPhone {
                            Text("Sign in to\nPermanent")
                                .font(
                                    .custom(
                                        "Usual-Regular",
                                        size: 32)
                                )
                                .fontWeight(.light)
                                .lineSpacing(8)
                                .foregroundStyle(.white)
                        } else {
                            Text("Sign in to Permanent")
                                .font(
                                    .custom(
                                        "Usual-Regular",
                                        size: 32)
                                )
                                .fontWeight(.light)
                                .lineSpacing(8)
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .layoutPriority(1)
                    if showEmptySpace {
                        Spacer()
                    }
                    VStack(spacing: 16) {
                        CustomLoginFormView(username: $viewModel.username, password: $viewModel.password, focusedField: _focusedField) {
                            signIn()
                        }
                        RoundButtonRightImageView(text: "Sign in", action: {
                            signIn()
                        })
                    }
                    Button(action: {
                        self.viewModel.containerViewModel.setContentType(.forgotPassword)
                    }, label: {
                        Text("Forgot password?")
                            .font(
                                .custom("Usual-Regular", size: 14)
                                .weight(.medium)
                            )
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                    })
                    HStack(spacing: 20) {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(height: 1)
                            .background(Color(red: 0.54, green: 0.55, blue: 0.64))
                            .layoutPriority(0.5)
                        Text("New to Permanent?".uppercased())
                            .font(
                                .custom("Usual-Regular", size: 10))
                            .kerning(1.6)
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(red: 0.72, green: 0.73, blue: 0.79))
                            .layoutPriority(1)
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(height: 1)
                            .background(Color(red: 0.54, green: 0.55, blue: 0.64))
                            .layoutPriority(0.5)
                        
                    }
                    SmallRoundButtonImageView(type: .noColor, imagePlace: .onRight, text: "Sign Up", image: Image(.iconauthUserPlus), action: {
                        self.viewModel.containerViewModel.setContentType(.register)
                    })
                    
                    if !showEmptySpace {
                        Spacer()
                            .layoutPriority(0.5)
                    }
                }
            }
        }
        .onChange(of: viewModel.loginStatus, perform: { status in
            if let _ = status {
                switch status {
                case .success:
                    if AuthenticationManager.shared.session?.account.defaultArchiveID != nil {
                        AppDelegate.shared.rootViewController.setDrawerRoot()
                    } else {
                        let screenView = OnboardingView(viewModel: OnboardingContainerViewModel(username: viewModel.username, password: viewModel.password))
                        let host = UIHostingController(rootView: screenView)
                        host.modalPresentationStyle = .fullScreen
                        AppDelegate.shared.rootViewController.present(host, animated: true)
                    }
                    viewModel.trackLoginEvent()
                    loginSuccess()
                    
                case .mfaToken:
                    self.viewModel.containerViewModel.setContentType(.verifyIdentity)
                    break
                default:
                    break
                }
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { event in
            if let keyboardSize = event.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                if keyboardSize.size.height > 120 {
                    if !keyboardOpenend {
                        keyboardOpenend = true
                        withAnimation(.linear(duration: 0.3)) {
                            showEmptySpace = false
                        }
                    }
                }
            }
        }.onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { event in
            if let keyboardSize = event.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                if keyboardSize.size.height > 120 {
                    if keyboardOpenend && self.focusedField == nil{
                        keyboardOpenend = false
                        withAnimation(.linear(duration: 0.3)) {
                            showEmptySpace = true
                        }
                    }
                }
            }
        }
        .onTapGesture {
            withAnimation {
                showEmptySpace = true
            }
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func signIn() {
        withAnimation {
            showEmptySpace = true
        }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        viewModel.attemptLogin()
    }
}

#Preview {
    GeometryReader { geometry in
        ZStack {
            Gradient.darkLightBlueGradient
            HStack(spacing: 64) {
                if !Constants.Design.isPhone {
                    AuthLeftSideView(viewModel: AuthLeftSideViewModel(containerViewModel: AuthenticatorContainerViewModel()), startExploringAction: {
                        UIApplication.shared.open(URL(string: "https://www.permanent.org/gallery")!)
                    })
                    .frame(width: geometry.size.width * 0.70)
                    .cornerRadius(12)
                }
                VStack(spacing: 0) {
                    LoginView(viewModel: LoginViewModel(containerViewModel: AuthenticatorContainerViewModel()), loginSuccess: {
                        
                    })
                    Spacer()
                }
            }
            .padding(Constants.Design.isPhone ? 32 : 64)
        }
    }
    .ignoresSafeArea(.all)
}
