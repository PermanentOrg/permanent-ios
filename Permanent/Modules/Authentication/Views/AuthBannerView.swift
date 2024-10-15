//
//  ErrorBannerView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.09.2024.

import SwiftUI

struct AuthBannerView: View {
    let message: AuthBannerMessage
    @Binding var isVisible: Bool
    var isError: Bool {
        if message == .successResendCode {
            return false
        }
        return true
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
                .disabled(true)
            if isVisible {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        HStack {
                            Group {
                                if isError {
                                    Image(.authNotificationError)
                                } else {
                                    Image(.authNotificationSuccess)
                                }
                                Text("\(message.text)")
                                    .font(.custom("Usual-Regular", size: 14))
                                    .foregroundColor(isError ? Color(red: 0.94, green: 0.27, blue: 0.22) : Color(.success600))
                            }
                        }
                        Spacer()
                        Button(action: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                            withAnimation {
                                isVisible = false
                            }
                        }, label: {
                            if isError {
                                Text(message == .codeExpiredError ? "Resend" : "OK")
                                    .font(.custom("Usual-Regular", size: 14)
                                        .weight(.medium)
                                    )
                                    .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
                            } else {
                                Image(.authCloseBannerSuccess)
                            }
                        })
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(isError ? Color(red: 1, green: 0.89, blue: 0.89) : Color(red: 0.92, green: 0.99, blue: 0.95))
                    .cornerRadius(12)
                    .shadow(color: Color(red: 0.07, green: 0.11, blue: 0.29).opacity(0.12), radius: 16, x: 0, y: 24)
                    Color.clear
                        .frame(height: Constants.Design.isPhone ? 32 : 64)
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut(duration: 0.3), value: isVisible)
            }
        }
    }
}

#Preview {
    ZStack {
        Gradient.darkLightBlueGradient
            .ignoresSafeArea()
        AuthBannerView(message: .invalidCredentials, isVisible: .constant(true))
    }
}
