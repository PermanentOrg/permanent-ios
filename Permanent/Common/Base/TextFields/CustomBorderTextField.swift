//
//  CustomBorderTextField.swift
//  Permanent
//
//  Created by Lucian Cerbu on 19.04.2024.

import SwiftUI

struct CustomBorderTextField: View {
    @Binding var textFieldText: String
    var placeholder: String = "Enter your text here"
    var preText: String = "The"
    var afterText: String = "Archive"
    
    var body: some View {
        if Constants.Design.isPhone {
            HStack(alignment: .center, spacing: 8) {
                Text("\(preText)")
                    .textStyle(UsualRegularTextStyle())
                    .foregroundColor(.white)
                TextField("", text: $textFieldText)
                    .textStyle(UsualRegularMediumTextStyle())
                    .foregroundColor(.white)
                    .placeholder(when: textFieldText.isEmpty) {
                        Text("\(placeholder)")
                            .textStyle(UsualRegularTextStyle())
                            .foregroundColor(.blue400)
                            .lineLimit(1)
                    }
                Spacer()
                Text("\(afterText)")
                    .textStyle(UsualRegularTextStyle())
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 0)
            .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 56, alignment: .leading)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .inset(by: 0.5)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
                
            )
        } else {
            HStack(alignment: .center, spacing: 8) {
                Text("\(preText)")
                    .textStyle(UsualRegularMediumLargeTextStyle())
                    .foregroundColor(.white)
                TextField("", text: $textFieldText)
                    .textStyle(UsualMediumLargeTextStyle())
                    .foregroundColor(.white)
                    .placeholder(when: textFieldText.isEmpty) {
                        Text("\(placeholder)")
                            .textStyle(UsualRegularMediumLargeTextStyle())
                            .foregroundColor(.blue400)
                            .lineLimit(1)
                    }
                Spacer()
                Text("\(afterText)")
                    .textStyle(UsualRegularMediumLargeTextStyle())
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 0)
            .frame(maxWidth: .infinity, minHeight: 72, maxHeight: 72, alignment: .leading)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .inset(by: 0.5)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
                
            )
        }
    }
}
