//
//  SettingsScreenView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.01.2024.

import SwiftUI

struct SettingsScreenView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: SettingsScreenViewModel
    var settingsRouter: SettingsRouter
    /// The no-archive onboarding account menu hides everything that needs an
    /// archive or doesn't apply yet: the storage usage bar, and the Storage,
    /// "My archives", and Legacy Planning rows, plus the "finish setup" affordance
    /// (its checklist target — MainViewController — doesn't exist during onboarding).
    var isOnboardingMenu: Bool = false

    init(viewModel: StateObject<SettingsScreenViewModel>, router: SettingsRouter, isOnboardingMenu: Bool = false) {
        self._viewModel = viewModel
        self.settingsRouter = router
        self.isOnboardingMenu = isOnboardingMenu
    }
    
    var dismissAction: ((Bool) -> Void)?
    @State private var showSignOutConfirmation = false
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                modernBody
            } else {
                legacyBody
            }
        }
    }

    @available(iOS 26.0, *)
    private var modernBody: some View {
        NavigationStack {
            ZStack {
                backgroundView
                contentView
                RevokeBottomAlertView(
                    isPresented: $showSignOutConfirmation,
                    title: "Are you sure you want to sign out?",
                    buttonText: "Sign out",
                    onRevoke: { viewModel.signOut() }
                )
            }
            .ignoresSafeArea(.all)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
        }
        .presentationCornerRadius(20)
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

    private var legacyBody: some View {
        ZStack {
            backgroundView
            contentView
            RevokeBottomAlertView(
                isPresented: $showSignOutConfirmation,
                title: "Are you sure you want to sign out?",
                buttonText: "Sign out",
                onRevoke: { viewModel.signOut() }
            )
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
                    VStack {
                        if #available(iOS 26.0, *) {
                            CustomHeaderView(url: viewModel.selectedArchiveThumbnailURL, titleText: viewModel.accountFullName, descText: viewModel.accountEmail, fontType: .usual, showFinishSetUpAccount: viewModel.showFinishSetUpAccount && !isOnboardingMenu, showCloseButton: false) {
                                settingsRouter.navigate(to: .memberChecklist, router: settingsRouter)
                            }
                        } else {
                            CustomHeaderView(url: viewModel.selectedArchiveThumbnailURL, titleText: viewModel.accountFullName, descText: viewModel.accountEmail, fontType: .usual, showFinishSetUpAccount: viewModel.showFinishSetUpAccount && !isOnboardingMenu) {
                                settingsRouter.navigate(to: .memberChecklist, router: settingsRouter)
                            }
                        }
                    }

                    if !isOnboardingMenu {
                        GradientProgressBarView(value: viewModel.spaceUsedReadable, maxValue: viewModel.spaceTotalReadable, sizeRatio: viewModel.spaceRatio, colorScheme: .lightWithGradientBar, fontType: .usual)
                            .padding(.horizontal, 5)
                    }
                    Group {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading) {
                                Button {
                                    settingsRouter.navigate(to: .account, router: settingsRouter)
                                } label: {
                                    CustomSimpleListItemView(image: Image(.accountSettings), titleText: "Account")
                                }
                                .accessibilityIdentifier("settingsAccountOption")
                                if !isOnboardingMenu {
                                    Button {
                                        settingsRouter.navigate(to: .storage, router: settingsRouter)
                                    } label: {
                                        CustomSimpleListItemView(image: Image(.storageSettings), titleText: "Storage")
                                    }
                                    .accessibilityIdentifier("settingsStorageOption")
                                }
                                if !isOnboardingMenu {
                                    Button {
                                        settingsRouter.navigate(to: .myArchives, router: settingsRouter)
                                    } label: {
                                        CustomSimpleListItemView(image: Image(.myArchivesSettings), titleText: "My archives")
                                    }
                                    .accessibilityIdentifier("settingsMyArchivesOption")
                                }
                                Button {
                                    settingsRouter.navigate(to: .invitations, router: settingsRouter)
                                } label: {
                                    CustomSimpleListItemView(image: Image(.invitationsSettings), titleText: "Invitations")
                                }
                                .accessibilityIdentifier("settingsInvitationsOption")
                                Button {
                                    settingsRouter.navigate(to: .activityFeed, router: settingsRouter)
                                } label: {
                                    CustomSimpleListItemView(image: Image(.activityFeedSettings), titleText: "Activity feed")
                                }
                                .accessibilityIdentifier("settingsActivityFeedOption")
                                Button {
                                    settingsRouter.navigate(to: .loginAndSecurity, router: settingsRouter)
                                } label: {
                                    CustomSimpleListItemView(image: Image(.securitySettings), titleText: "Login & Security", notificationIcon: !(viewModel.twoFactorAuthenticationEnabled == true)&&(viewModel.isLoading2FAStatus == false))
                                }
                                .accessibilityIdentifier("settingsLoginSecurityOption")
                                if !isOnboardingMenu {
                                    Button {
                                        settingsRouter.navigate(to: .legacyPlanning, router: settingsRouter)
                                    } label: {
                                        CustomSimpleListItemView(image: Image(.legacyPlanningSettings), titleText: "Legacy Planning")
                                    }
                                    .accessibilityIdentifier("settingsLegacyPlanningOption")
                                }
                                Spacer()
                            }
                        }
                        .onAppear {
                            ScrollViewAppearanceManager.shared.pushScrollViewBounce(enabled: false, identifier: "SettingsScreen")
                            viewModel.trackEvents()
                        }
                        .onDisappear {
                            ScrollViewAppearanceManager.shared.popScrollViewBounce(identifier: "SettingsScreen")
                        }
                        Divider()
                            .padding(.horizontal, -40)
                        Button {
                            showSignOutConfirmation = true
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


