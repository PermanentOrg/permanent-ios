//
//  NewBadgeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.12.2023.

import SwiftUI

struct NewBadgeView: View {
    var body: some View {
        HStack {
            if #available(iOS 16, *) {
                Text("NEW")
                    .textStyle(SmallXXXXXSemiBoldTextStyle())
                    .kerning(1.6)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
            } else {
                Text("NEW")
                    .textStyle(SmallXXXXXSemiBoldTextStyle())
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
            }
        }
        .frame(height: 24)
        .padding(.horizontal, 8)
        .padding(.vertical, 0)
        .background(Color(.yellow))
        .cornerRadius(20)
    }
}
