//
//  AccessRoleChipView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 10.07.2024.

import SwiftUI

struct AccessRoleChipView: View {
    var text: String
    var textColor: Color = .white
    var body: some View {
        HStack {
            if #available(iOS 16, *) {
                Text("\(text.uppercased())")
                    .textStyle(UsualSmallXXXXXRegularTextStyle())
                    .kerning(1.6)
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor)
            } else {
                Text("\(text.uppercased())")
                    .textStyle(UsualSmallXXXXXRegularTextStyle())
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor)
            }
        }
        .frame(height: 24)
        .padding(.horizontal, 8)
        .padding(.vertical, 0)
        .background(Color(.white).opacity(0.08))
        .cornerRadius(6)
    }
}

#Preview {
    ZStack {
        Color(.primary)
        AccessRoleChipView(text: "Owner", textColor: .white)
    }
    .ignoresSafeArea()
}
