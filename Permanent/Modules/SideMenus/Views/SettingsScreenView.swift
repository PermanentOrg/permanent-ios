//
//  SettingsScreenView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.01.2024.

import SwiftUI

struct SettingsScreenView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: SettingsScreenViewModel
    var settingsRouter: SettingsRouter
    
    init(viewModel: StateObject<SettingsScreenViewModel>, router: SettingsRouter) {
        self._viewModel = viewModel
        self.settingsRouter = router
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
        .onChange(of: viewModel.loggedOut) { loggedOut in
            if loggedOut {
                settingsRouter.navigate(to: .signUp, router: settingsRouter)
            }
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(title: Text("Error"), message: Text("Something went wrong. Please try again later."), dismissButton: .default(Text(String.ok)) {
                viewModel.showError = false
            })
        }
    }
    
    var backgroundView: some View {
        Color.white
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
    }
    
    var contentView: some View {
            ZStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    CustomHeaderView(url: viewModel.selectedArchiveThumbnailURL, titleText: viewModel.accountFullName, descText: viewModel.accountEmail, fontType: .usual)
                    GradientProgressBarView(value: viewModel.spaceUsedReadable, maxValue: viewModel.spaceTotalReadable, sizeRatio: viewModel.spaceRatio, colorScheme: .lightWithGradientBar, fontType: .usual)
                        .padding(.horizontal, 5)
                    Group {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading) {
                                Button {
                                    settingsRouter.navigate(to: .account, router: settingsRouter)
                                } label: {
                                    CustomSimpleListItemView(image: Image(.accountSettings), titleText: "Account")
                                }
                                Button {
                                    settingsRouter.navigate(to: .storage, router: settingsRouter)
                                } label: {
                                    CustomSimpleListItemView(image: Image(.storageSettings), titleText: "Storage")
                                }
                                Button {
                                    settingsRouter.navigate(to: .myArchives, router: settingsRouter)
                                } label: {
                                    CustomSimpleListItemView(image: Image(.myArchivesSettings), titleText: "My archives")
                                }
                                Button {
                                    settingsRouter.navigate(to: .invitations, router: settingsRouter)
                                } label: {
                                    CustomSimpleListItemView(image: Image(.invitationsSettings), titleText: "Invitations")
                                }
                                Button {
                                    settingsRouter.navigate(to: .activityFeed, router: settingsRouter)
                                } label: {
                                    CustomSimpleListItemView(image: Image(.activityFeedSettings), titleText: "Activity feed")
                                }
                                Button {
                                    settingsRouter.navigate(to: .loginAndSecurity, router: settingsRouter)
                                } label: {
                                    CustomSimpleListItemView(image: Image(.securitySettings), titleText: "Login & Security", notificationIcon: true)
                                }
                                Button {
                                    settingsRouter.navigate(to: .legacyPlanning, router: settingsRouter)
                                } label: {
                                    CustomSimpleListItemView(image: Image(.legacyPlanningSettings), titleText: "Legacy Planning")
                                }
                                Spacer()
                            }
                        }
                        .onAppear {
                            UIScrollView.appearance().bounces = false
                        }
                        .onDisappear {
                            UIScrollView.appearance().bounces = true
                        }
                        Divider()
                            .padding(.horizontal, -40)
                        Button {
                            viewModel.signOut()
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
