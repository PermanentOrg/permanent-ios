//
//  CustomRegisterFormView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 21.10.2024.

import SwiftUI

enum RegisterFocusField: Hashable {
    case fullname, email, password
}

struct CustomRegisterFormView: View {
    @Binding var fullname: String
    @Binding var email: String
    @Binding var password: String
    @FocusState var focusedField: RegisterFocusField?
    
    var onSubmit: () -> Void
    var actionForFirstFieldTap: (() -> Void)
    var actionForLastFieldTap: (() -> Void)
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("", text: $fullname)
                .textStyle(UsualSmallXRegularTextStyle())
                .placeholder(when: fullname.isEmpty) {
                    Text("Full name".uppercased())
                        .foregroundColor(.white)
                        .font(.custom("Usual-Regular", size: 10))
                        .kerning(1.6)
                        .lineLimit(1)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 0)
                .frame(height: 56, alignment: .leading)
                .background(.white.opacity(0.04))
                .cornerRadius(12)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .textContentType(.emailAddress)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.5)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                )
                .focused($focusedField, equals: .fullname)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .email
                }
                .clipShape(.rect(cornerRadius: 4))
                .onTapGesture {
                    focusedField = .fullname
                    actionForFirstFieldTap()
                }
            
            TextField("", text: $email)
                .textStyle(UsualSmallXRegularTextStyle())
                .placeholder(when: email.isEmpty) {
                    Text("Email address".uppercased())
                        .foregroundColor(.white)
                        .font(.custom("Usual-Regular", size: 10))
                        .kerning(1.6)
                        .lineLimit(1)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 0)
                .frame(height: 56, alignment: .leading)
                .background(.white.opacity(0.04))
                .cornerRadius(12)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .textContentType(.emailAddress)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.5)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                )
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .password
                }
                .clipShape(.rect(cornerRadius: 4))
                .onTapGesture {
                    focusedField = .email
                    actionForFirstFieldTap()
                }
            
            SecureField("", text: $password)
                .font(.custom("Usual-Regular", size: 14))
                .foregroundColor(.white)
                .placeholder(when: password.isEmpty) {
                    Text("Password".uppercased())
                        .font(.custom("Usual", size: 10))
                        .kerning(1.6)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 0)
                .textContentType(.password)
                .frame(height: 56, alignment: .leading)
                .background(.white.opacity(0.04))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.5)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                )
                .focused($focusedField, equals: .password)
                .submitLabel(.continue)
                .onSubmit {
                    onSubmit()
                }
                .clipShape(.rect(cornerRadius: 4))
                .onTapGesture {
                    focusedField = .password
                    actionForLastFieldTap()
                }
        }
    }
}
