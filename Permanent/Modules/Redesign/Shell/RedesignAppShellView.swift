//
//  RedesignAppShellView.swift
//  Permanent
//
//  Stage 6 app shell: a Dashboard ↔ Files container with a floating bottom-nav
//  pill + a context "+" FAB. The Files tab hosts the existing UIKit file manager
//  (`MainViewController`) via `FilesContainerRepresentable` (full parity, zero
//  grid-rewrite risk). The Dashboard tab shows the redesign dashboard.
//
//  The Files tab is SECTION-AWARE (Private / Public / Shared). The UIKit drawer
//  switches the section in place through `RedesignShellCoordinator` instead of
//  swapping the whole root out from under the shell — so the bottom nav, shared
//  header, and Dashboard tab survive and stay reachable on every navigation path.
//
//  Only reachable when `DashboardRedesign.isEnabled`.
//

import SwiftUI

/// The file collections the Files tab can host. The drawer's left-menu items
/// (Private / Public / Shared Files) switch between these in place.
enum RedesignFilesSection: Hashable {
    case privateFiles
    case publicFiles
    case shared
}

/// Shared coordinator that lets the UIKit drawer drive the SwiftUI shell: switch
/// the active tab and the Files-tab section WITHOUT tearing the shell down.
/// Owned by `RedesignAppShellEntry.makeShellHost(coordinator:)` and retained by
/// the `DrawerViewController` so `SideMenuViewController` can reach it.
final class RedesignShellCoordinator: ObservableObject {
    @Published var selectedTab: RedesignShellTab = .files
    @Published var filesSection: RedesignFilesSection = .privateFiles
    /// Bumped to force the Files host to rebuild even when re-selecting the same
    /// section (e.g. tapping "Private Files" again should reset to the root).
    @Published var filesReloadToken: Int = 0

    /// Switch the Files tab to `section`, make Files the active tab, and rebuild
    /// the hosted file manager.
    func showFiles(_ section: RedesignFilesSection) {
        filesSection = section
        selectedTab = .files
        filesReloadToken += 1
    }
}

struct RedesignAppShellView: View {
    @ObservedObject var coordinator: RedesignShellCoordinator
    @StateObject private var filesController = FilesTabController()
    @StateObject private var drawerController = ShellDrawerController()

    var body: some View {
        ZStack(alignment: .bottom) {
            // One shared header above BOTH tabs + the switching content below it.
            VStack(spacing: 0) {
                RedesignShellHeader(
                    title: headerTitle,
                    onMenu: { drawerController.openDrawer?() },
                    trailing: { headerTrailing }
                )

                currentTab
            }

            // Floating bottom-nav pill + context "+" FAB. The Dashboard ↔ Files
            // toggle is the app's home navigation, so it shows on the Dashboard
            // tab and on Private Files. Shared / Public Files are drawer
            // excursions (reached via the hamburger), so the pill is hidden there
            // — you return through the drawer, exactly like the legacy app.
            if showsBottomNav {
                RedesignBottomNavBar(
                    selection: $coordinator.selectedTab,
                    showsAdd: coordinator.selectedTab == .files && coordinator.filesSection == .privateFiles,
                    onAdd: { filesController.showAddMenu?() }
                )
                .padding(.bottom, 8)
                .transition(.opacity)
            }

            // Invisible bridge to the UIKit drawer plumbing (hamburger/settings).
            ShellDrawerBridge(controller: drawerController)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea(.keyboard)
    }

    /// The Dashboard|Files pill shows on the Dashboard tab and on Private Files
    /// only. Shared / Public Files (drawer destinations) hide it.
    private var showsBottomNav: Bool {
        switch coordinator.selectedTab {
        case .dashboard: return true
        case .files:     return coordinator.filesSection == .privateFiles
        }
    }

    private var headerTitle: String {
        if coordinator.selectedTab == .dashboard { return "My Dashboard" }
        switch coordinator.filesSection {
        case .privateFiles: return "Private Files"
        case .publicFiles:  return "Public Files"
        case .shared:       return "Shared Files"
        }
    }

    /// Trailing buttons. Search is Files-only (there's nothing to search on the
    /// Dashboard), so it's hidden on the Dashboard tab; the person/profile button
    /// shows on both and opens settings (the right-side menu) until a redesign
    /// profile exists.
    @ViewBuilder
    private var headerTrailing: some View {
        if coordinator.selectedTab == .files {
            RedesignShellHeaderButton(systemName: "magnifyingglass", accessibilityID: "shellSearchButton") {
                filesController.showSearch?()
            }
        }
        RedesignShellHeaderButton(systemName: "person", accessibilityID: "shellProfileButton") {
            (filesController.showSettings ?? drawerController.openSettings)?()
        }
    }

    @ViewBuilder
    private var currentTab: some View {
        // Both tabs stay mounted (opacity-gated) so switching tabs preserves the
        // file manager's folder location / scroll. The Files host rebuilds only
        // when the section changes (via `.id(filesReloadToken)`).
        ZStack {
            RedesignHomeDashboardView()
                .opacity(coordinator.selectedTab == .dashboard ? 1 : 0)
                .allowsHitTesting(coordinator.selectedTab == .dashboard)

            FilesContainerRepresentable(controller: filesController, section: coordinator.filesSection)
                .id(coordinator.filesReloadToken)
                .ignoresSafeArea(edges: .bottom)
                .opacity(coordinator.selectedTab == .files ? 1 : 0)
                .allowsHitTesting(coordinator.selectedTab == .files)
        }
    }
}

#Preview {
    RedesignAppShellView(coordinator: RedesignShellCoordinator())
}
