//
//  SecurityDetailView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 06.03.2025.

import SwiftUI

struct SecurityDetailView: View {
    @EnvironmentObject var navigationManager: NavigationStateManager
    
    var body: some View {
        switch navigationManager.selectionState {
        case .changePassword:
            ChangePasswordView()
        case .twoStepVerification:
            TwoStepVerificationView(
                isTwoFactorEnabled: false,
                twoFactorMethods: []
            )
        default:
            VStack(spacing: 32) {
                Image(systemName: "shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                Text("Select a security option")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.whiteGray)
        }
    }
}
