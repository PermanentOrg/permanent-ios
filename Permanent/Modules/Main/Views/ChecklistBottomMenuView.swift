//
//  ChecklistBottomMenu.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.05.2025.


import SwiftUI
import UIKit

enum ChecklistViewState {
    case loading
    case content
    case dontShowAgain
    case error
}

struct ChecklistBottomMenuView: View {
    @StateObject var viewModel: ChecklistBottomMenuViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var redraw = UUID()
    var dismissAction: (() -> Void)
    
    init(viewModel: StateObject<ChecklistBottomMenuViewModel>, dismissAction: @escaping () -> Void) {
        self._viewModel = viewModel
        self.dismissAction = dismissAction
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 16) {
                        HStack(alignment: .center, spacing: 16) {
                            HStack(alignment: .center, spacing: 0) {
                                Image(.memberChecklistTitleLogo)
                                .frame(width: 24, height: 24)
                            }
                            .frame(width:40, height: 40, alignment: .center)
                            .background(.white)
                            .cornerRadius(40)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Getting started")
                                    .font(.custom("Usual-Regular", size: 14)
                                    .weight(.medium)
                                    )
                                .foregroundColor(Color(red: 0.07, green: 0.11, blue: 0.29))
                                Text("Let's finish setting up your account")
                                  .font(.custom("Usual-Regular", size: 12))
                                  .foregroundColor(Color(red: 0.35, green: 0.37, blue: 0.5))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(.memberchecklistMinus)
                                    .frame(width: 24, height: 24, alignment: .center)
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 88)
                    .background(Color(red: 0.96, green: 0.96, blue: 0.99))
                    
                    // Content
                    switch viewModel.viewState {
                    case .loading:
                        ChecklistLoadingView()
                    case .content:
                        ChecklistOptionsView(
                            items: viewModel.items,
                            completionPercentage: viewModel.completionPercentage,
                            redraw: redraw,
                            onDisableChecklist: {
                                viewModel.viewState = .dontShowAgain
                            }
                        )
                    case .dontShowAgain:
                        ChecklistDisableView {
                            viewModel.setHideChecklist { result in
                                if result {
                                    self.dismissAction()
                                    presentationMode.wrappedValue.dismiss()
                                } else {
                                    viewModel.viewState = .error
                                }
                            }
                        } onCancel: {
                            viewModel.viewState = .content
                        }

                    case .error:
                        ChecklistErrorView {
                            viewModel.getMemberChecklist()
                        }
                    }
                }
            }
        }
        .background(Color.white)
    }
}

struct ChecklistBottomMenu_Previews: PreviewProvider {
    static var previews: some View {
        ChecklistBottomMenuView(viewModel: StateObject(wrappedValue: ChecklistBottomMenuViewModel()), dismissAction: {
            
        })
    }
}
