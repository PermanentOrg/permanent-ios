//
//  RedesignAppShellEntry.swift
//  Permanent
//
//  Entry point that wraps the Stage 6 SwiftUI app shell in a UIHostingController
//  so it can be hosted by the existing UIKit drawer/root plumbing, behind
//  `DashboardRedesign.isEnabled`.
//

import SwiftUI
import UIKit

enum RedesignAppShellEntry {
    /// Builds the shell host. The caller creates and retains the `coordinator`
    /// (the `DrawerViewController` keeps it) so the UIKit drawer can drive the
    /// shell's tab/section in place instead of swapping the root.
    static func makeShellHost(coordinator: RedesignShellCoordinator) -> UIViewController {
        UIHostingController(rootView: RedesignAppShellView(coordinator: coordinator))
    }
}
