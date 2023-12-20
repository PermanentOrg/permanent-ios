//
//  RedeemCodeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 13.12.2023.

import SwiftUI

struct RedeemCodeView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: RedeemCodeViewModel
    
    var dismissAction: ((Bool) -> Void)?
    
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Redeem gift code for free storage")
                .textStyle(RegularSemiBoldTextStyle())
                .foregroundColor(.blue900)
            Text("If you have a gift code, redeem it for complimentary storage below.")
                .textStyle(SmallXRegularTextStyle())
                .foregroundColor(.blue700)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            if #available(iOS 16.0, *) {
                Text("Enter code".uppercased())
                    .textStyle(SmallXXXXXRegularTextStyle())
                    .foregroundColor(.blue700)
                    .padding(.top, 16)
                    .kerning(1.6)
            } else {
                Text("Enter code".uppercased())
                    .textStyle(SmallXXXXXRegularTextStyle())
                    .foregroundColor(.blue700)
                    .padding(.top, 16)
            }
            RoundStyledTextFieldView(text: $viewModel.redeemCode, placeholderText: "Enter redeem code...", invalidField: viewModel.invalidDataInserted) {
                viewModel.redeemCodeRequest()
            }
            RoundButtonView(isDisabled: viewModel.invalidDataInserted, isLoading: viewModel.isLoading, text: "Redeem") {
                viewModel.redeemCodeRequest()
            }
            .padding(.top, 16)
            Spacer()
        }
        .padding()
        .navigationBarTitle("Redeem Storage", displayMode: .inline)
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
        dismissAction?(false)
        presentationMode.wrappedValue.dismiss()
    }
}
