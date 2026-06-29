//
//  FilesContainerRepresentable.swift
//  Permanent
//
//  Hosts the proven UIKit file manager (`MainViewController`) inside the Stage 6
//  SwiftUI shell via `UIViewControllerRepresentable`. The grid, folder
//  drill-down, search, and the create/upload FAB menu all come along for free —
//  no grid rewrite.
//
//  The hosted (inner) RootNavigationController's nav bar is HIDDEN: the shell
//  renders a single shared `RedesignShellHeader` above both tabs, and the file
//  manager's title/hamburger/search/settings actions are surfaced there.
//  `FilesTabController` exposes `showAddMenu`, `showSearch`, and `showSettings`,
//  wired to `MainViewController.didTap()`, `searchButtonPressed(_:)`, and the
//  drawer's `didTapRightSideMenuButton()` respectively. The MainViewController's
//  on-screen FABView is removed so only the shell's single "+" is visible.
//
//  The `drawerDelegate` is still resolved at runtime from the ancestor chain so
//  the shared hamburger/settings toggle the real `DrawerViewController` menu.
//
//  Only reachable when `DashboardRedesign.isEnabled`.
//

import SwiftUI
import UIKit

/// Bridges the SwiftUI shell to the hosted UIKit file manager. The shell's "+"
/// invokes `showAddMenu`, which is wired to `MainViewController.didTap()`.
final class FilesTabController: ObservableObject {
    /// Set by the representable once the MainViewController exists; calling it
    /// opens the create/upload menu (same as tapping the legacy file FAB).
    var showAddMenu: (() -> Void)?
    /// Opens the file-manager search (same as the legacy search nav button);
    /// wired to `MainViewController.searchButtonPressed(_:)`.
    var showSearch: (() -> Void)?
    /// Opens settings / the right-side menu (same as the legacy settings nav
    /// button); wired to the drawer's `didTapRightSideMenuButton()`.
    var showSettings: (() -> Void)?
}

struct FilesContainerRepresentable: UIViewControllerRepresentable {
    @ObservedObject var controller: FilesTabController
    /// Which file collection to host. Switched in place by the drawer through
    /// `RedesignShellCoordinator` so the shell survives.
    var section: RedesignFilesSection = .privateFiles

    func makeUIViewController(context: Context) -> RootNavigationController {
        let rootVC: UIViewController

        switch section {
        case .privateFiles, .publicFiles:
            // Private / Public both use MainViewController with a different VM —
            // the same instances the legacy drawer path builds.
            let mainVC = UIViewController.create(withIdentifier: .main, from: .main)
            if let filesVC = mainVC as? MainViewController {
                filesVC.viewModel = (section == .publicFiles) ? PublicFilesViewModel() : MyFilesViewModel()
                // Shell hosting: keep the root nav bar hidden (the shell header is
                // the chrome) and reserve a bottom inset that clears the floating
                // pill. The delegate (below) reveals the bar for pushed screens.
                filesVC.hostedInShell = true

                // The shell provides the single "+" FAB. The VC re-shows its own
                // on-screen FABView from several code paths (viewDidLoad,
                // updateFABViewVisibility, FAB-menu dismissal), so toggling
                // `isHidden` isn't enough. Removing it from the hierarchy is
                // bulletproof: the VC only ever flips isHidden/alpha, never re-adds
                // it, so a detached FABView can never become visible again.
                filesVC.loadViewIfNeeded()
                filesVC.fabView?.removeFromSuperview()

                // Route the shell's "+" to the file manager's create/upload menu.
                controller.showAddMenu = { [weak filesVC] in
                    filesVC?.didTap()
                }
                // Route the shared header's search button to the file manager's
                // search (MainViewController.searchButtonPressed(_:)).
                controller.showSearch = { [weak filesVC] in
                    filesVC?.searchButtonPressed(filesVC as Any)
                }
            }
            rootVC = mainVC

        case .shared:
            // Shared uses SharesViewController (a different VC, not a MainVC VM).
            let sharesVC = UIViewController.create(withIdentifier: .shares, from: .share)
            if let shares = sharesVC as? SharesViewController {
                shares.selectedIndex = ShareListType.sharedWithMe.rawValue
            }
            // Shares has no upload FAB or search hook — clear them so the shell
            // hides the "+" and the search button for this section.
            controller.showAddMenu = nil
            controller.showSearch = nil
            rootVC = sharesVC
        }

        // Wrap in RootNavigationController so folder drill-down works exactly as
        // it does in the legacy drawer path. The file manager's OWN nav bar is
        // hidden — the shell renders the single shared header above both tabs.
        // The coordinator reveals the bar (with a back button) for PUSHED screens
        // (e.g. share preview) so they aren't stuck under a hidden bar, and hides
        // it again at the root.
        let navController = RootNavigationController(viewController: rootVC)
        navController.setNavigationBarHidden(true, animated: false)
        navController.delegate = context.coordinator
        return navController
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    /// Keeps the root file view bar-less (the shell header is the chrome) while
    /// giving pushed screens a nav bar + back button.
    final class Coordinator: NSObject, UINavigationControllerDelegate {
        func navigationController(_ navigationController: UINavigationController,
                                  willShow viewController: UIViewController,
                                  animated: Bool) {
            let isRoot = navigationController.viewControllers.count <= 1
            navigationController.setNavigationBarHidden(isRoot, animated: animated)
        }
    }

    func updateUIViewController(_ uiViewController: RootNavigationController, context: Context) {
        // Keep the hosted nav bar hidden (the shared header owns the chrome).
        if !uiViewController.isNavigationBarHidden {
            uiViewController.setNavigationBarHidden(true, animated: false)
        }

        // The hamburger/settings buttons forward to `drawerDelegate`. The real
        // delegate is the DrawerViewController, which only wired the OUTER nav
        // controller (the one hosting this shell). Resolve it from the ancestor
        // chain so the inner path toggles the same side menu, and route the
        // shared header's settings button through it.
        if uiViewController.drawerDelegate == nil,
           let delegate = uiViewController.nearestDrawerMenuDelegate() {
            uiViewController.drawerDelegate = delegate
        }
        if controller.showSettings == nil,
           let delegate = uiViewController.drawerDelegate {
            controller.showSettings = { [weak delegate] in
                delegate?.didTapRightSideMenuButton()
            }
        }
    }
}

private extension UIViewController {
    /// Walks the parent chain looking for a `DrawerMenuDelegate` (the
    /// DrawerViewController). Skips `self` so an inner RootNavigationController
    /// doesn't resolve to itself.
    func nearestDrawerMenuDelegate() -> DrawerMenuDelegate? {
        var node = parent
        while let current = node {
            if let delegate = current as? DrawerMenuDelegate {
                return delegate
            }
            node = current.parent
        }
        return nil
    }
}
