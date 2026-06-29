//
//  ShellDrawerBridge.swift
//  Permanent
//
//  Bridges the SwiftUI app shell's shared header back to the UIKit drawer
//  plumbing so the shared hamburger opens the same left side menu, and (on the
//  Files tab) the settings button opens the same right-side settings, that the
//  legacy nav bar used.
//
//  The shell host (`UIHostingController(RedesignAppShellView())`) is wrapped in
//  an OUTER `RootNavigationController` whose `drawerDelegate` is the
//  `DrawerViewController`. A tiny `UIViewControllerRepresentable` resolves that
//  outer nav controller from the host's ancestor chain and publishes
//  `didTapDrawerMenuButton` (open left drawer) and `didTapRightSideMenuButton`
//  (open settings) into a `ShellDrawerController` the shell can call. This works
//  identically from BOTH tabs because the header lives above both.
//
//  Only reachable when `DashboardRedesign.isEnabled`.
//

import SwiftUI
import UIKit

/// Holds the resolved drawer actions for the shell's shared header.
final class ShellDrawerController: ObservableObject {
    /// Opens the left side menu (same as the legacy hamburger).
    var openDrawer: (() -> Void)?
    /// Opens settings / the right-side menu (same as the legacy settings button).
    var openSettings: (() -> Void)?
}

/// Resolves the outer `RootNavigationController.drawerDelegate` (the
/// `DrawerViewController`) from the host's ancestor chain and wires its
/// menu/settings actions into the supplied `ShellDrawerController`.
struct ShellDrawerBridge: UIViewControllerRepresentable {
    @ObservedObject var controller: ShellDrawerController

    func makeUIViewController(context: Context) -> BridgeViewController {
        BridgeViewController(controller: controller)
    }

    func updateUIViewController(_ uiViewController: BridgeViewController, context: Context) {
        uiViewController.resolveDelegateIfNeeded()
    }

    /// An invisible UIKit anchor placed in the shell hierarchy so we can walk
    /// the ancestor chain to the outer drawer-owning nav controller.
    final class BridgeViewController: UIViewController {
        private weak var controller: ShellDrawerController?

        init(controller: ShellDrawerController) {
            self.controller = controller
            super.init(nibName: nil, bundle: nil)
            view.isUserInteractionEnabled = false
            view.backgroundColor = .clear
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            resolveDelegateIfNeeded()
        }

        func resolveDelegateIfNeeded() {
            guard let controller, controller.openDrawer == nil else { return }
            guard let delegate = nearestDrawerMenuDelegate() else { return }
            controller.openDrawer = { [weak delegate] in
                delegate?.didTapDrawerMenuButton()
            }
            controller.openSettings = { [weak delegate] in
                delegate?.didTapRightSideMenuButton()
            }
        }

        /// Walks the parent chain looking for the `DrawerMenuDelegate`. The outer
        /// `RootNavigationController` forwards to its `drawerDelegate`
        /// (the `DrawerViewController`), so resolving the nav controller and
        /// using its delegate hits the real drawer.
        private func nearestDrawerMenuDelegate() -> DrawerMenuDelegate? {
            var node = parent
            while let current = node {
                if let nav = current as? RootNavigationController,
                   let delegate = nav.drawerDelegate {
                    return delegate
                }
                if let delegate = current as? DrawerMenuDelegate, !(current is RootNavigationController) {
                    return delegate
                }
                node = current.parent
            }
            return nil
        }
    }
}
