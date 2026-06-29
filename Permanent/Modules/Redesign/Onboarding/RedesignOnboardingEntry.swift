//
//  RedesignOnboardingEntry.swift
//  Permanent
//
//  Builds the redesigned onboarding-dashboard as a UIHostingController to present
//  wherever the legacy OnboardingView was shown (login, register, MFA verify,
//  biometrics/relaunch), behind `DashboardRedesign.isEnabled`, for users without
//  a default archive. No credentials needed — the create flow refreshes the
//  session via reloadSession. The "What's important" + "Chart your path"
//  selections ride along on the create's single addRemoveTags call. On success
//  the user lands in the file manager and this host is dismissed.
//
//  The header's profile button opens the same account menu (`SettingsScreenView`)
//  the shell shows — matching Android. In the no-archive state it simply shows no
//  archives, and its "Sign out" row handles logout. To give that menu's
//  `SettingsRouter` a real navigation controller to present from, the host is
//  wrapped in a `RootNavigationController` (nav bar hidden, exactly like the
//  shell).
//

import SwiftUI
import UIKit

enum RedesignOnboardingEntry {
    static func makeDashboardHost() -> UIViewController {
        // Resolved after `nav` is built; captured weakly so the profile closure
        // (retained by the SwiftUI view → host → nav) doesn't form a cycle.
        weak var weakNav: RootNavigationController?

        let view = RedesignOnboardingRootView(
            onFinished: {
                AppDelegate.shared.rootViewController.setDrawerRoot()
                AppDelegate.shared.rootViewController.dismiss(animated: true)
            },
            onProfile: { presentAccountMenu(from: weakNav) }
        )

        let host = UIHostingController(rootView: view)
        // Wrap so the account menu's SettingsRouter has a nav controller to
        // present from. Hide the bar — the onboarding has its own SwiftUI header.
        let nav = RootNavigationController(viewController: host)
        nav.setNavigationBarHidden(true, animated: false)
        nav.modalPresentationStyle = .fullScreen
        weakNav = nav
        return nav
    }

    /// Presents the account / settings menu over the onboarding (matches Android).
    private static func presentAccountMenu(from nav: RootNavigationController?) {
        guard let nav else { return }
        let router = OnboardingSettingsRouter(rootViewController: nav)
        router.navigate(to: .settings, router: router)
    }
}

/// `SettingsRouter` for the onboarding account menu, with two onboarding-specific
/// tweaks over the shared router:
///  • `.settings` is presented with the "finish setup" (member checklist)
///    affordance hidden — its target screen (MainViewController) only exists inside
///    the drawer/shell, which onboarding never builds, so it would be a dead-end.
///  • `.signUp` (sign-out) first tears down the onboarding modal stack — the
///    onboarding is a modal over the app root (unlike the shell, a root child), so
///    otherwise `setRoot(.signUp)` swaps the root while login stays hidden behind it.
private final class OnboardingSettingsRouter: SettingsRouter {
    override func navigate(to page: Page, router: SettingsRouter) {
        switch page {
        case .settings:
            ScrollViewAppearanceManager.shared.reset()
            let screenView = SettingsScreenView(
                viewModel: StateObject(wrappedValue: SettingsScreenViewModel()),
                router: router,
                isOnboardingMenu: true
            )
            let host = UIHostingController(rootView: screenView)
            host.sheetPresentationController?.detents = [.large()]
            rootViewController.present(host, animated: true)

        case .signUp:
            // Dismiss the onboarding (+ its settings sheet) so the login screen
            // that `super` swaps in below is actually revealed.
            AppDelegate.shared.rootViewController.dismiss(animated: false)
            super.navigate(to: page, router: router)

        default:
            super.navigate(to: page, router: router)
        }
    }
}
