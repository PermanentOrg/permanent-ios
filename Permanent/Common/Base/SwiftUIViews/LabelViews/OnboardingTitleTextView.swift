//
//  OnboardingTitleTextView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.06.2024.

import SwiftUI

struct OnboardingTitleTextView: View {
    var preText: String
    var boldText: String
    var postText: String

    var body: some View {
        VStack {
            HStack {
                Text("\(preText)")
                + Text("\(boldText)")
                    .bold()
                + Text("\(postText)")
            }
            .font(
                .custom(
                    FontName.usualLight.rawValue,
                    fixedSize: Constants.Design.isPhone ? 32 : 56)
            )
            .foregroundColor(.white)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineSpacing(8.0)
            
        }
    }
}

#Preview {
    return ZStack {
        Color(.primary)
        OnboardingTitleTextView(
            preText: "Hello, ",
            boldText: "User with long name.",
            postText: "Welcome to Permanent!"
        )
    }
    .ignoresSafeArea()
}
