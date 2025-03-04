//
//  CustomEmailFieldView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 31.01.2025.

import SwiftUI

enum EmailFocusField: Hashable {
    case isFocused
}

struct CustomEmailFieldView: View {
    @Binding var email: String
    
    var onSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("", text: $email, prompt: Text(verbatim: "example@email.com").foregroundColor(.blue200))
                .font(.custom("Usual-Regular", size: 14))
                .foregroundColor(.blue900)
                .padding(.horizontal, 12)
                .padding(.vertical, 0)
                .frame(height: 56, alignment: .leading)
                .background(.white.opacity(0.04))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .textContentType(.emailAddress)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.5)
                        .stroke(Color.blue100, lineWidth: 1)
                )
                .submitLabel(.done)
                .onSubmit {
                    onSubmit()
                }
                .clipShape(.rect(cornerRadius: 4))
        }
    }
}
