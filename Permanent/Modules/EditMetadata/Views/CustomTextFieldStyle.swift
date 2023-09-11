//
//  CustomTextFieldStyle.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.08.2023.

import SwiftUI

struct CustomTextFieldStyle: TextFieldStyle {
    var leftView: AnyView? = nil
    var rightView: AnyView? = nil
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .foregroundColor(.clear)
                .frame(height: 48)
                .background(Color(red: 0.96, green: 0.96, blue: 0.99).opacity(0.5))
                .cornerRadius(2)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .inset(by: 0.5)
                        .stroke(Color(red: 0.96, green: 0.96, blue: 0.99), lineWidth: 1)
                )
            HStack {
                leftView?
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color(red: 0.71, green: 0.71, blue: 0.71))
                configuration
                    .padding(.leading, 16)
                    .foregroundColor(Color.darkBlue)
                    .frame(height: 18)
                    .autocorrectionDisabled(true)
                    .autocapitalization(.none)
                Spacer(minLength: 0)
                rightView?
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color(red: 0.71, green: 0.71, blue: 0.71))
            }
            .padding(.horizontal, 16)
        }
    }
}
