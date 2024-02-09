//
//  ViewRepresentableContainer.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.02.2024.

import SwiftUI

struct ViewRepresentableContainer: View {
    @Environment(\.presentationMode) var presentationMode

    var viewRepresentable: any UIViewControllerRepresentable
    var title: String
    
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
            AnyView(viewRepresentable)
                .ignoresSafeArea()
        }
        .navigationBarTitle(title, displayMode: .inline)
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
