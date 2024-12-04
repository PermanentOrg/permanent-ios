//
//  RedeemCodeView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 13.12.2023.

import SwiftUI
import Combine

struct RedeemCodeView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: RedeemCodeViewModel
    @State private var showInvalidAlertView = false
    @ObservedObject var keyboard = KeyboardResponder()
    
    var dismissAction: ((Int) -> Void)?
    
    var body: some View {
        ZStack {
            CustomNavigationView {
                ZStack {
                    backgroundView
                        .onTapGesture {
                            dismissKeyboard()
                        }
                    contentView
                }
                .ignoresSafeArea(.all)
            } leftButton: {
                backButton
            } rightButton: {
                EmptyView()
            }
        }
        .onChange(of: viewModel.showAlert) { showAlert in
            withAnimation {
                showInvalidAlertView = showAlert
            }
        }
        .onChange(of: viewModel.codeRedeemed, perform: { value in
            dismissView()
        })
        .onAppear(perform: {
            viewModel.trackOpenReedeemCode()
        })
    }
    
    var backgroundView: some View {
        Color.whiteGray
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
    }
    
    var contentView: some View {
        ZStack(alignment: .bottom) {
            if showInvalidAlertView {
                BottomInvalidAlertMessageView(alertTextTitle: "The code is invalid.", alertTextDescription: "Enter a new code.") {
                    viewModel.showAlert = false
                }
                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .opacity))
                .padding(.bottom, keyboard.currentHeight == .zero ? 16 : keyboard.currentHeight - 10)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Redeem gift code for storage")
                    .textStyle(RegularSemiBoldTextStyle())
                    .foregroundColor(.blue900)
                Text("If you have a gift code, redeem it for storage below.")
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
                RoundButtonView(isDisabled: viewModel.isConfirmButtonDisabled, isLoading: viewModel.isLoading, text: "Redeem") {
                    viewModel.redeemCodeRequest()
                }
                .padding(.top, 16)
                Spacer()
            }
            .onTapGesture {
                dismissKeyboard()
            }
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
        dismissAction?(viewModel.storageRedeemed)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
