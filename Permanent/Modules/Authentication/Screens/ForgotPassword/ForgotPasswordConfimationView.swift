//
//  ForgotPasswordConfimationView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04.10.2024.


import SwiftUI

struct ForgotPasswordConfimationView: View {
    @StateObject var viewModel: AuthenticatorContainerViewModel
    @State var showEmptySpace: Bool = true
    @FocusState var focusedField: LoginFocusField?
    @State var keyboardOpenend: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                HStack() {
                    Image(.authLogo)
                        .frame(height: Constants.Design.isPhone ? 32 : 64)
                    Spacer()
                }
                HStack() {
                    if Constants.Design.isPhone {
                        Text("Forgot your\npassword?")
                            .font(
                                .custom(
                                    "Usual-Regular",
                                    size: 32)
                            )
                            .fontWeight(.light)
                            .lineSpacing(8)
                            .foregroundStyle(.white)
                    } else {
                        Text("Forgot your password?")
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
                HStack {
                    Text("Thank you! If your email was found in our system, you will receive an email shortly.")
                        .font(
                            .custom("Usual-Regular", size: 14)
                        )
                        .lineSpacing(6)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white)
                        .frame(height: 75)
                    Spacer()
                }
                .layoutPriority(1)
                SmallRoundButtonImageView(type: .noColor, imagePlace: .onRight, text: "Go to Sign in", image: Image(.rightArrowShort), action: {
                    viewModel.setContentType(.login)
                })
                Spacer()
            }
        }
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
                    .frame(width: geometry.size.width * 0.58)
                    .cornerRadius(12)
                }
                VStack(spacing: 0) {
                    ForgotPasswordConfimationView(viewModel: AuthenticatorContainerViewModel())
                    Spacer()
                }
            }
            .padding(Constants.Design.isPhone ? 32 : 64)
        }
    }
    .ignoresSafeArea(.all)
}
