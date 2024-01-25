//
//  RoundStyledTextFieldView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 19.12.2023.

import SwiftUI

struct RoundStyledTextFieldView: View {
    @Binding var text: String
    var placeholderText: String
    var invalidField: Bool
    var doneAction: (() -> Void)
    
    var body: some View {
        ZStack {
            Color(.white)
            if #available(iOS 16.0, *) {
                TextField(placeholderText, text: $text)
                    .modifier(RegularTextStyle())
                    .foregroundColor(Color.darkBlue)
                    .frame(height: 18)
                    .autocorrectionDisabled(true)
                    .autocapitalization(.none)
                    .padding(.horizontal)
                    .submitLabel(.done)
                    .onSubmit(doneAction)
            } else {
                TextField(placeholderText, text: $text, onCommit: doneAction)
                    .modifier(RegularTextStyle())
                    .foregroundColor(Color.darkBlue)
                    .frame(height: 18)
                    .autocorrectionDisabled(true)
                    .autocapitalization(.none)
                    .padding(.horizontal)
            }
        }
        .frame(minHeight: 48, maxHeight: 48, alignment: .leading)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(invalidField ? Color.error200 : Color.blue50)
        )
    }
}
