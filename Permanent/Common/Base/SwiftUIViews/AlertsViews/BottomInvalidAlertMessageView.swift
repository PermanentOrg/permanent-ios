//
//  BottomInvalidAlertMessageView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 21.12.2023.

import SwiftUI

struct BottomInvalidAlertMessageView: View {
    var alertTextTitle: String
    var alertTextDescription: String
    var closeAction: (() -> Void)
    
    var body: some View {
        ZStack {
            Color(.error25)
            HStack(alignment: .top) {
                Image(.explanationMarkRed)
                VStack(alignment: .leading) {
                    Text(alertTextTitle)
                        .textStyle(SmallXRegularTextStyle())
                        .foregroundColor(.error500)
                    Text(alertTextDescription)
                        .textStyle(SmallXXXRegularTextStyle())
                        .foregroundColor(.blue600)
                }
                Spacer()
                Button(action: closeAction) {
                    Image(.closeNavigationRed)
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
                .stroke(Color(.error200), lineWidth: 1)
        )
        .padding(.bottom, 24)
    }
}
    
