//
//  TwoStepConfirmationContainerView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 21.01.2025.

import SwiftUI

struct TwoStepConfirmationContainerView: View {
    @StateObject var viewModel: TwoStepConfirmationContainerViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        SimpleCustomNavigationView(content: {
            ZStack(alignment: .top) {
                switch viewModel.contentType {
                case .confirmPassword:
                    TwoStepConfirmPasswordView(viewModel: TwoStepConfirmPasswordViewModel(containerViewModel: viewModel))
                        .transition(AnyTransition.asymmetric(
                            insertion: viewModel.insertionViewTransition,
                            removal: .opacity)
                        )
                case .chooseVerification:
                    TwoStepChooseVerificationView(viewModel: TwoStepChooseVerificationViewModel(containerViewModel: viewModel))
                        .transition(AnyTransition.asymmetric(
                            insertion: viewModel.insertionViewTransition,
                            removal: .opacity)
                        )
                default:
                    EmptyView()
                }
                TwoStepBottomNotificationView(message: viewModel.bannerErrorMessage, isVisible: $viewModel.showErrorBanner)
                    .padding(.bottom, Constants.Design.isPhone ? -32 : -64)
            }
            .padding(32)
            .navigationBarTitle(viewModel.contentType.screenTitle(), displayMode: .inline)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }, leftButton: {
            switch viewModel.contentType {
            case .chooseVerification:
                Button {
                    viewModel.setContentType(.confirmPassword)
                } label: {
                    Image(.twoStepBack)
                        .frame(width: 24, height: 24)
                }
            default:
                EmptyView()
            }
        }, rightButton: {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(.twoStepClose)
                    .frame(width: 24, height: 24)
            }
        },
                                   backgroundColor: .white,
                                   textColor: UIColor(Color.blue900),
                                   textStyle: TextFontStyle.style50,
                                   showLeftChevron: false
        )
    }
}
