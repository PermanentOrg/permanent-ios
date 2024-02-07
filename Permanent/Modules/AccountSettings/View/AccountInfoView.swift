//
//  AccountInfoView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 06.02.2024.

import SwiftUI
import UIKit

struct AccountInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            CustomNavigationView {
                ZStack {
                    backgroundView
                    contentView
                }
                .ignoresSafeArea(.all)
            } leftButton: {
                backButton
            } rightButton: {
                EmptyView()
            }
        }
    }
    
    var backgroundView: some View {
        Color.whiteGray
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
    }
    
    var contentView: some View {
        VStack {
            AccountInfoViewControllerRepresentable()
                .ignoresSafeArea()
        }
        .navigationBarTitle("Account", displayMode: .inline)
    }
    
    var backButton: some View {
        Button(action: {
            dismissView()
        }) {
            HStack {
                Image(.backArrowNewDesign)
                    .foregroundColor(.white)
            }
        }
    }
    
    func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
}
