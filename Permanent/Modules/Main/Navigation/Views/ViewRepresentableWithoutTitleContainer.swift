//
//  ViewRepresentableWithoutTitleContainer.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.03.2025.


import SwiftUI

struct ViewRepresentableWithoutTitleContainer: View {
    var viewRepresentable: any UIViewControllerRepresentable
    
    var body: some View {
        ZStack {
            backgroundView
            contentView
        }
        .ignoresSafeArea(.all)
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
    }
}
