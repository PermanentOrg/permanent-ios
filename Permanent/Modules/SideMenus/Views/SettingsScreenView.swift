//
//  SettingsScreenView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.01.2024.

import SwiftUI

struct SettingsScreenView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: SettingsScreenViewModel
    
    init(viewModel: StateObject<SettingsScreenViewModel>) {
        self._viewModel = viewModel
    }
    
    var dismissAction: ((Bool) -> Void)?
    
    var body: some View {
        ZStack {
            backgroundView
            contentView
        }
        .ignoresSafeArea(.all)
        .onDisappear(perform: {
            dismissAction?(false)
        })
        .fullScreenCover(isPresented: $viewModel.storageIsPresented, onDismiss: {
            dismissView()
        }, content: {
            StorageView(viewModel: StateObject(wrappedValue: StorageViewModel.init()))
        })
    }
    
    var backgroundView: some View {
        Color.white
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
    }
    
    var contentView: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading) {
                CustomWhiteNavigationView(url: viewModel.selectedArchiveThumbnailURL, titleText: viewModel.accountFullName, descText: viewModel.accountEmail)
                GradientProgressBarView(value: viewModel.spaceUsedReadable, maxValue: viewModel.spaceTotalReadable, sizeRatio: viewModel.spaceRatio, colorScheme: .settings)
                    .padding(.horizontal, 5)
                Group {
                    Button {
                        viewModel.accountIsPresented = true
                    } label: {
                        CustomSimpleListItemView(image: Image(.accountSettings), titleText: "Account")
                    }
                    Button {
                        viewModel.storageIsPresented = true
                    } label: {
                        CustomSimpleListItemView(image: Image(.storageSettings), titleText: "Storage")
                    }
                    Button {
                        viewModel.myArchivesIspresented = true
                    } label: {
                        CustomSimpleListItemView(image: Image(.myArchivesSettings), titleText: "My archives")
                    }
                    Button {
                        viewModel.invitationsIsPresented = true
                    } label: {
                        CustomSimpleListItemView(image: Image(.invitationsSettings), titleText: "Invitations")
                    }
                    Button {
                        viewModel.activityFeedIspresented = true
                    } label: {
                        CustomSimpleListItemView(image: Image(.activityFeedSettings), titleText: "Activity feed")
                    }
                    Button {
                        viewModel.securityIspresented = true
                    } label: {
                        CustomSimpleListItemView(image: Image(.securitySettings), titleText: "Security")
                    }
                    Button {
                        viewModel.legacyPlanningIspresented = true
                    } label: {
                        CustomSimpleListItemView(image: Image(.legacyPlanningSettings), titleText: "Legacy Planning")
                    }
                    Spacer()
                    Divider()
                        .padding(.horizontal, -40)
                    Button {
                        print("logout")
                    } label: {
                        CustomSimpleListItemView(image: Image(.signOutSettings), titleText: "Sign out", color: .error500)
                    }
                }
                .padding(.horizontal, 10)
            }
        }
        .padding(.bottom, 20)
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

#Preview {
    SettingsScreenView(viewModel: StateObject(wrappedValue: SettingsScreenViewModel()))
}
