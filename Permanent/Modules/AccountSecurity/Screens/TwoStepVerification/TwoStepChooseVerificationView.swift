//
//  TwoStepChooseVerificationView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.01.2025.

import SwiftUI

struct TwoStepChooseVerificationView: View {
    @StateObject var viewModel: TwoStepChooseVerificationViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(TwoStepMethodType.allCases, id: \.rawValue) { item in
                Divider()
                Button {
                    if item == .email {
                        withAnimation {
                            viewModel.isEmailMethodSelected = true
                        }
                    } else {
                        withAnimation {
                            viewModel.isEmailMethodSelected = false
                        }
                    }
                } label: {
                    if item == .email {
                        TwoStepConfirmationItemView(isSelected: self.viewModel.isEmailMethodSelected ?? false, type: item)
                    } else {
                        TwoStepConfirmationItemView(isSelected: !(self.viewModel.isEmailMethodSelected ?? true), type: item)
                    }
                    
                }
                .transaction { transaction in
                    transaction.animation = nil
                }
            }
            Spacer()
                .frame(maxHeight: .infinity)
            RoundButtonUsualFontView(isDisabled: viewModel.isEmailMethodSelected == nil, isLoading: false, text: "Continue") {
                if viewModel.isEmailMethodSelected ?? false{
                    viewModel.containerViewModel.setContentType(.chooseEmail)
                } else {
                    viewModel.containerViewModel.setContentType(.choosePhoneNumber)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

struct TwoStepConfirmationItemView: View {
    var isSelected: Bool = false
    var type: TwoStepMethodType
    
    init(isSelected: Bool, type: TwoStepMethodType) {
        self.isSelected = isSelected
        self.type = type
    }
    
    var body: some View {
        ZStack {
            Color(isSelected ? .fadeGray : .white)
            
            if type == .email {
                VStack {
                    HStack(spacing: 24) {
                        Image(.twoStepEmailIcon)
                            .frame(width: 24, height: 24)
                        if isSelected {
                            Text(type.name())
                                .font(
                                    .custom(
                                        "Usual-Medium",
                                        fixedSize: 14)
                                )
                                .foregroundColor(.blue900)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(type.name())
                                .font(
                                    .custom(
                                        "Usual-Regular",
                                        fixedSize: 14)
                                )
                                .foregroundColor(.blue900)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        
                        Image(isSelected ? .twoStepCheckMark : .twoStepEmptyCheckmark)
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(.horizontal, 24)
            } else {
                HStack(spacing: 24) {
                    Image(.twoStepSMSIcon)
                        .frame(width: 24, height: 24)
                    HStack(spacing: 8) {
                        if isSelected {
                            Text(type.name())
                                .font(
                                    .custom(
                                        "Usual-Medium",
                                        fixedSize: 14)
                                )
                                .foregroundColor(.blue900)
                                .multilineTextAlignment(.leading)
                                .lineLimit(1)
                        } else {
                            Text(type.name())
                                .font(
                                    .custom(
                                        "Usual-Regular",
                                        fixedSize: 14)
                                )
                                .foregroundColor(.blue900)
                                .multilineTextAlignment(.leading)
                                .lineLimit(1)
                        }
                        HStack(alignment: .center) {
                            Text("usa only".uppercased())
                                .font(
                                    .custom(
                                        "Usual-Regular",
                                        fixedSize: 10)
                                )
                                .fontWeight(.medium)
                                .kerning(1.6)
                                .foregroundColor(.blue900)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                        }
                        .frame(height: 24)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 0)
                        .background(isSelected ? .white : .fadeGray)
                        .cornerRadius(6)
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(isSelected ? .twoStepCheckMark : .twoStepEmptyCheckmark)
                        .frame(width: 24, height: 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .frame(height: 72)
        .frame(maxWidth: .infinity)
    }
}

enum TwoStepMethodType: String, Identifiable, CaseIterable {
    var id: String { return self.rawValue }
    
    case email
    case sms
    
    func name() -> String {
        switch self {
        case .email:
            return "Email"
        case .sms:
            return "Text message (SMS)"
        }
    }
}

