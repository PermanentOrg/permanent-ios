//
//  AuthVerifyIdentityView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.09.2024.

import SwiftUI

struct AuthVerifyIdentityView: View {
    @StateObject var viewModel: AuthVerifyIdentityViewModel
    @State var showEmptySpace: Bool = true
    @State var keyboardOpenend: Bool = false
    @FocusState var focusedPin: FocusPin?
    
    var loginSuccess: (() -> Void)
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                HStack() {
                    Image(.authLogo)
                        .frame(height: Constants.Design.isPhone ? 32 : 64)
                    Spacer()
                }
                HStack() {
                    Text("Verify your identity")
                        .font(
                            .custom(
                                "Usual-Regular",
                                size: 32)
                        )
                        .fontWeight(.light)
                        .lineSpacing(8)
                        .foregroundStyle(.white)
                    Spacer()
                }
                .layoutPriority(1)
                HStack {
                    Text("Please check your email or SMS for the 4-digit code and enter it below.")
                        .font(
                            .custom("Usual-Regular", size: 14)
                        )
                        .lineSpacing(6)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white)
                        .frame(height: 56)
                    Spacer()
                }
                .layoutPriority(1)
                
                if showEmptySpace {
                    Spacer()
                }
                VStack(spacing: 24) {
                    Login2FAFieldView(numberOfFields: 4, code: $viewModel.pinCode, pinFocusState: focusedPin)
                    RoundButtonRightImageView(text: "Verify", action: {
                        signIn()
                    },hasImage: false)
                }
                if showEmptySpace {
                    Spacer()
                }
                HStack(spacing: 20) {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(height: 1)
                        .background(Color(red: 0.54, green: 0.55, blue: 0.64))
                        .layoutPriority(0.5)
                    Text("Didn't receive the code?".uppercased())
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
                SmallRoundButtonImageView(type: .noColor, imagePlace: .none, text: "Resend code", image: Image(.iconauthUserPlus), action: {
                    viewModel.resendPinCode()
                })
                
                Text("OR".uppercased())
                    .font(
                        .custom("Usual-Regular", size: 10))
                    .kerning(1.6)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(red: 0.72, green: 0.73, blue: 0.79))
//                    .layoutPriority(1)
                Button(action: {
                    UIApplication.shared.open(URL(string: "https://permanent.zohodesk.com/portal/en/newticket/")!)
                }, label: {
                    Text("Contact Support")
                        .font(
                            .custom("Usual-Regular", size: 14)
                            .weight(.medium)
                        )
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                })
                if !showEmptySpace {
                    Spacer()
                }
            }
        }
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
                    if keyboardOpenend && self.focusedPin == nil{
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
        viewModel.verify2FA { status in
            switch status {
            case .success:
                if AuthenticationManager.shared.session?.account.defaultArchiveID != nil {
                    AppDelegate.shared.rootViewController.setDrawerRoot()
                } else {
                    let screenView = OnboardingView(viewModel: OnboardingContainerViewModel(username: nil, password: nil))
                    let host = UIHostingController(rootView: screenView)
                    host.modalPresentationStyle = .fullScreen
                    AppDelegate.shared.rootViewController.present(host, animated: true)
                }
                loginSuccess()
            default:
                return
            }
        }
    }
}

#Preview {
    GeometryReader { geometry in
        ZStack {
            Gradient.darkLightBlueGradient
                .ignoresSafeArea()
            VStack(spacing: 0) {
                AuthVerifyIdentityView(viewModel: AuthVerifyIdentityViewModel(containerViewModel: AuthenticatorContainerViewModel()), loginSuccess: {
                })
            }
        }
    }
    .ignoresSafeArea(.keyboard)
}
