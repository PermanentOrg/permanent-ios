//
//  ChecklistCongratsView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.05.2025.
import SwiftUI

struct ChecklistCongratsView: View {
    let onHideMemberChecklistBtn: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Account set up")
                            .foregroundColor(Color(red: 0.35, green: 0.37, blue: 0.5))
                            .font(.custom("Usual-Regular", size: 12))
                            .fontWeight(.regular)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("100%")
                            .foregroundColor(.black)
                            .font(.custom("Usual-Regular", size: 12))
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    ProgressView(value: 1.0)
                        .progressViewStyle(CustomBarProgressGradientStyle(colorScheme: .solidGreenWithWhiteBar, height: 8, cornerRadius: 3))
                        .frame(height: 8)
                }
                .padding(.vertical, 16)
                
                Image(.memberchecklistCongrats)
                    .frame(width: 40, height: 40)
                
                Text("You’re all set!")
                    .font(.custom("Usual-Regular", size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(.blue900)
                    .multilineTextAlignment(.center)
                
                Text("You’ve completed your account setup and are ready to make the most of Permanent.\nCreate. Share. Preserve.")
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(.blue700)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .frame(maxWidth: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 32)
            .padding(.bottom, 120)
            GreyRoundButtonUsualView(isDisabled: false, isLoading: false, text: "Don’t show me this again", action: onHideMemberChecklistBtn)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
