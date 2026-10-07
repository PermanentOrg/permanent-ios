//
//  ContextMenuDeferral.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.09.2026.
//

import UIKit

/// Holds a context menu's picked action, and any list reload, until the menu has finished closing.
/// A screen that opens while the menu still animates away can fail to appear, and a reload under an open menu breaks its lifted row.
final class ContextMenuDeferral {
    private(set) var isMenuShown = false
    private var generation = 0
    private var pendingAction: (() -> Void)?
    private var pendingReloads: [() -> Void] = []
    private let fallbackDelay: TimeInterval

    /// `fallbackDelay` ends a menu whose closing animation never reports back.
    init(fallbackDelay: TimeInterval = 1) {
        self.fallbackDelay = fallbackDelay
    }

    func menuWillShow() {
        generation += 1
        isMenuShown = true
    }

    func menuWillEnd(animator: UIContextMenuInteractionAnimating?) {
        let ending = generation
        guard let animator else { return finish(ending) }
        animator.addCompletion { [weak self] in self?.finish(ending) }
        DispatchQueue.main.asyncAfter(deadline: .now() + fallbackDelay) { [weak self] in self?.finish(ending) }
    }

    /// Ends the menu now, for a screen that goes away with the menu up, or a lifted row's tap that has closed it.
    func menuIsGone() {
        finish(generation)
    }

    /// Runs `action` once the menu is gone; UIKit can call a menu item before or after it starts closing.
    func run(_ action: @escaping () -> Void) {
        if isMenuShown {
            pendingAction = action
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }

    /// True when the reload must wait for the menu; held reloads then run in order once it closes.
    func holdsReload(_ reload: @escaping () -> Void) -> Bool {
        guard isMenuShown else { return false }
        pendingReloads.append(reload)
        return true
    }

    /// Only the newest menu's end counts, so a late animation cannot release the work under another open menu.
    private func finish(_ ending: Int) {
        guard ending == generation, isMenuShown else { return }
        isMenuShown = false
        let reloads = pendingReloads, action = pendingAction
        pendingReloads = []
        pendingAction = nil
        reloads.forEach { $0() }
        action?()
    }
}
