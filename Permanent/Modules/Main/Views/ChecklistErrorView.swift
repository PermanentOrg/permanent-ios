//
//  ChecklistErrorView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.05.2025.
import SwiftUI

struct ChecklistErrorView: View {
    let onRefreshChecklist: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 16) {
                Image(.memberChecklistError)
                    .renderingMode(.template)
                    .frame(width: 48, height: 48)
                    .foregroundColor(.error500)
                
                Text("Something went wrong!")
                    .font(.custom("Usual-Regular", size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(.blue900)
                    .multilineTextAlignment(.center)
                
                Text("You will no longer receive account setup progress reminders. Are you sure you want to hide this checklist?")
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(.blue600)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(32)
            .padding(.bottom, 120)
            RoundButtonUsualFontView(isDisabled: false, isLoading: false, text: "Refresh", action: onRefreshChecklist)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
