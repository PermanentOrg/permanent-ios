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
        ZStack{
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
                        TwoStepChooseVerificationView(viewModel: TwoStepChooseVerificationViewModel(containerViewModel: viewModel, isEmailMethodSelected: nil))
                            .transition(AnyTransition.asymmetric(
                                insertion: viewModel.insertionViewTransition,
                                removal: .opacity)
                            )
                    case .chooseEmail:
                        TwoStepChooseEmailView(viewModel: TwoStepChooseEmailViewModel(containerViewModel: viewModel))
                            .transition(AnyTransition.asymmetric(
                                insertion: viewModel.insertionViewTransition,
                                removal: .opacity)
                            )
                    case .choosePhoneNumber:
                        TwoStepChoosePhoneView(viewModel: TwoStepChoosePhoneViewModel(containerViewModel: viewModel))
                            .transition(AnyTransition.asymmetric(
                                insertion: viewModel.insertionViewTransition,
                                removal: .opacity)
                            )
                    default:
                        EmptyView()
                    }
                    TwoStepBottomNotificationView(message: viewModel.bannerErrorMessage, isVisible: $viewModel.showErrorBanner)
                        .padding(.horizontal, 32)
                }
                .navigationBarTitle(viewModel.contentType.screenTitle(), displayMode: .inline)
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .onChange(of: viewModel.dismissContainer) { newValue in
                    if newValue {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }, leftButton: {
                switch viewModel.contentType {
                case .chooseEmail, .choosePhoneNumber:
                    Button {
                        viewModel.setContentType(.chooseVerification)
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
}
