//
//  AuthenticatorContainerView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.09.2024.

import SwiftUI

struct AuthenticatorContainerView: View {
    var body: some View {
        ZStack {
            Gradient.darkLightBlueGradient
            VStack() {
                Text("Hello, World!")
                    .foregroundColor(.white)
            }
        }
        .ignoresSafeArea(.all)
    }
}

#Preview {
    AuthenticatorContainerView()
}
