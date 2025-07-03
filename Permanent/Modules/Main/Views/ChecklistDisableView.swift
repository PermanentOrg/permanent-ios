//
//  ChecklistDisableView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.05.2025.
import SwiftUI

struct ChecklistDisableView: View {
    let onDisableChecklist: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 24) {
                Image(.memberChecklistDisableIcon)
                    .renderingMode(.template)
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue400)
                
                Text("You will no longer receive account setup progress reminders. Are you sure you want to hide this checklist?")
                    .font(.custom("Usual-Regular", size: 14))
                    .foregroundColor(.blue700)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .frame(maxWidth: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(32)
            .padding(.bottom, 120)
            
            VStack(spacing: 16) {
                RoundButtonUsualView(isDisabled: false, isLoading: false, text: "Yes", action: onDisableChecklist)
                GreyRoundButtonUsualView(isDisabled: false, isLoading: false, text: "Cancel", action: onCancel)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
