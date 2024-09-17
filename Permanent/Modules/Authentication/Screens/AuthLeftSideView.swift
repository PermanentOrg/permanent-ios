//
//  AuthLeftSideView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.09.2024.

import SwiftUI

struct AuthLeftSideView: View {
    @StateObject var viewModel: AuthLeftSideViewModel
    var startExploringAction: (() -> Void)
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AuthImageForRightSidePageView(page: .login)
            VStack(spacing: 0){
                VStack(alignment: .leading, spacing: 32) {
                    AuthTextForRightSidePageView(page: .login)
                    AuthTextForRightSidePageView(page: .login, isDescription: true)
                    Button {
                        startExploringAction()
                    } label: {
                        HStack(spacing: 16) {
                            Text("Start Exploring Now")
                                .font(
                                    .custom("Usual-Regular", size: 14)
                                    .weight(.medium)
                                )
                                .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
                            Image(.rightArrowShort)
                                .foregroundStyle(Color(red: 0.07, green: 0.11, blue: 0.29))
                                .frame(width: 24, height: 24)
                        }
                    }
                }
                .padding(32)
                .background(.white.opacity(0.84))
                .cornerRadius(12)
                .background(
                     Rectangle()
                        .fill(.gray.opacity(0.5))
                        .blur(radius: 6)
                )
            }
            .padding(64)
        }

    }
}

#Preview {
    AuthLeftSideView(viewModel: AuthLeftSideViewModel(containerViewModel: AuthenticatorContainerViewModel()), startExploringAction: {
    })
}
