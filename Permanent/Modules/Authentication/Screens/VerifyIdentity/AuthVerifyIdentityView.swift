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
    @State var keyboardHeight: CGFloat = 0
    @FocusState var focusedPin: FocusPinType?
    let bottomButtonId = UUID()
    let topElementId = UUID()
    
    var loginSuccess: (() -> Void)
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ScrollViewReader { scrollView in
                    ScrollView(showsIndicators: false) {
                            VStack(spacing: 32) {
                                if Constants.Design.isPhone {
                                    Color.clear
                                        .frame(height: 0)
                                }
                                HStack() {
                                    Image(.authLogo)
                                        .frame(height: Constants.Design.isPhone ? 32 : 64)
                                    Spacer()
                                }
//                                if geometry.size.height > 680 {
//                                    HStack() {
//                                        Image(.authLogo)
//                                            .frame(height: Constants.Design.isPhone ? 32 : 64)
//                                        Spacer()
//                                    }
//                                } else if showEmptySpace {
//                                    HStack() {
//                                        Image(.authLogo)
//                                            .frame(height: Constants.Design.isPhone ? 32 : 64)
//                                        Spacer()
//                                    }
//                                }
                                //.id(topElementId)
                                //.layoutPriority(2)
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
                                //.layoutPriority(1)
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
                                //.layoutPriority(1)
                                
                                if showEmptySpace && geometry.size.height > 680 {
                                    Spacer()
                                }
                                VStack(spacing: 24) {
                                    Login2FAFieldView(numberOfFields: 4,
                                                      code: $viewModel.pinCode,
                                                      focusedPin: Binding(
                                                        get: { focusedPin },
                                                        set: { newValue in
                                                            focusedPin = newValue
                                                        }
                                                      )
                                    )
                                    .id(bottomButtonId)
                                    RoundButtonRightImageView(text: "Verify", action: {
                                        signIn()
                                    },hasImage: false)
                                }
                                if showEmptySpace && geometry.size.height > 680 {
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
                                    if Constants.Design.isPhone {
                                        Spacer()
                                        
                                    } else {
                                        Spacer()
                                            .frame(height: keyboardHeight)
                                    }
                                    
                                }
                            }
                            .frame(height: geometry.size.height - (Constants.Design.isPhone ? 10 : 0))
                    }
                    .onAppear {
                        UIScrollView.appearance().bounces = false
                    }
                    .onDisappear {
                        UIScrollView.appearance().bounces = true
                    }
//                    .onChange(of: keyboardOpenend) { newValue in
//                        if newValue {
//                            scrollView.scrollTo(bottomButtonId)
//                        } else {
//                            scrollView.scrollTo(topElementId)
//                        }
//                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { event in
            if let keyboardSize = event.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardSize.size.height
                if keyboardHeight > 120 {
                    if !keyboardOpenend {
                        keyboardOpenend = true
                        withAnimation(.bouncy(duration: 0.3)) {
                            showEmptySpace = false
                        }
                    }
                }
            }
        }.onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)) { event in
            if let keyboardSize = event.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = 0
                if keyboardSize.height > 120 {
                    if keyboardOpenend {
                        keyboardOpenend = false
                        withAnimation(.bouncy(duration: 0.3)) {
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
            focusedPin = nil
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func signIn() {
        //        withAnimation {
        //            showEmptySpace = true
        //        }
        //        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        focusedPin = nil
       // UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
            if !Constants.Design.isPhone {
                HStack(spacing: 0) {
                    VStack {
                        AuthLeftSideView(viewModel: AuthLeftSideViewModel(containerViewModel: AuthenticatorContainerViewModel()), startExploringAction: {
                            UIApplication.shared.open(URL(string: "https://www.permanent.org/gallery")!)
                        })
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(12)
                        .padding(32)
                        .padding(.leading, 32)
                    }
                    .frame(maxWidth: geometry.size.width * 0.70)
                    .frame(height: geometry.size.height)
                    
                    AuthVerifyIdentityView(viewModel: AuthVerifyIdentityViewModel(containerViewModel: AuthenticatorContainerViewModel()), loginSuccess: {
                    })
                    .frame(width: geometry.size.width * 0.30)
                    .frame(maxHeight: .infinity)
                    .padding(EdgeInsets(top: 32, leading: 32, bottom: 32, trailing: 64))
                }
            }
            else {
                AuthVerifyIdentityView(viewModel: AuthVerifyIdentityViewModel(containerViewModel: AuthenticatorContainerViewModel()), loginSuccess: {
                })
                .frame(maxWidth: .infinity)
                .padding(32)
            }
        }
    }
    .ignoresSafeArea(.keyboard)
}
