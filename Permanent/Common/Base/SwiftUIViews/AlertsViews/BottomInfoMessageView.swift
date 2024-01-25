//
//  BottomInfoMessageView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 10.01.2024.

import SwiftUI

struct BottomInfoMessageView: View {
    var alertTextTitle: String
    var alertTextDescription: String
    var closeAction: (() -> Void)
    
    var body: some View {
        ZStack {
            Color(.success25)
            HStack(alignment: .top) {
                Image(.checkmarkGreen)
                VStack(alignment: .leading) {
                    Text(alertTextTitle)
                        .textStyle(SmallXRegularTextStyle())
                        .foregroundColor(.blue900)
                    Text(alertTextDescription)
                        .textStyle(SmallXXXRegularTextStyle())
                        .foregroundColor(.blue600)
                }
                Spacer()
                Button(action: closeAction) {
                    Image(.closeGreen)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .cornerRadius(12)
        .frame(height: 80)
        .shadow(color: Color(red: 0.07, green: 0.11, blue: 0.29).opacity(0.12), radius: 16, x: 0, y: 24)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .inset(by: 0.5)
                .stroke(Color(.success200), lineWidth: 1)
        )
        .padding(.bottom, 24)
    }
}
