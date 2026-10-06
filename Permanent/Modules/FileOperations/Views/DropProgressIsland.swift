//
//  DropProgressIsland.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.10.2026.
//

import UIKit

/// A drop's progress in the island Move Here uses: a spinner circle, then a check mark, then it closes.
/// One circle covers every drop under way, and VoiceOver hears when the moves start and end.
final class DropProgressIsland {
    struct Handlers {
        /// Opens the screen's island as the circle and returns it.
        let open: () -> FloatingActionIslandViewController?
        let current: () -> FloatingActionIslandViewController?
        let close: (@escaping () -> Void) -> Void
        let hidePlusButton: () -> Void
        /// Runs once the island has gone: the plus button comes back, or a bar that waited opens.
        let restore: () -> Void
    }

    private let handlers: Handlers
    private let announce: (String) -> Void
    private let progress = DropMoveProgress()
    private weak var circle: FloatingActionIslandViewController?
    private var isClosing = false
    private var checkCount = 0

    /// True while the circle is the screen's island, through its check mark and close.
    /// It asks the screen each time, because other code, such as a delete, can close the island too.
    var isShowing: Bool { circle != nil && circle === handlers.current() }

    init(handlers: Handlers, announce: @escaping (String) -> Void = { UIAccessibility.post(notification: .announcement, argument: $0) }) {
        self.handlers = handlers
        self.announce = announce
    }

    func moveStarted() {
        show(progress.begin())
    }

    func moveEnded(succeeded: Bool) {
        show(progress.end(succeeded: succeeded))
    }

    private func show(_ step: DropMoveProgress.Step) {
        // The end of a close gives a drop that is still under way a new circle.
        guard !isClosing else { return }
        switch step {
        case .none:
            break
        case .showSpinner:
            if let circle, isShowing {
                // A new drop takes over the circle while it still shows the last one's check.
                circle.hideDoneCheckmark()
                circle.showActivityIndicator()
                announce("Moving".localized())
            } else {
                openCircle()
            }
        case .showCheck:
            guard let circle, isShowing else { return }
            checkCount += 1
            let check = checkCount
            circle.hideActivityIndicator()
            circle.showDoneCheckmark { [weak self] in
                // Only the newest check closes the circle, and only when no drop is under way.
                guard let self, check == self.checkCount, !self.progress.isRunning else { return }
                self.dismiss()
            }
            announce("Moved".localized())
        case .close:
            guard let circle, isShowing else { return }
            circle.hideActivityIndicator()
            dismiss()
        }
    }

    /// Another island on screen, such as a Move bar, keeps its place, and the drop shows no circle.
    private func openCircle() {
        guard handlers.current() == nil else { return }
        handlers.hidePlusButton()
        circle = handlers.open()
        circle?.showActivityIndicator()
        announce("Moving".localized())
    }

    private func dismiss() {
        guard isShowing, !isClosing else { return }
        isClosing = true
        handlers.close { [weak self] in
            guard let self else { return }
            self.isClosing = false
            if self.progress.isRunning {
                self.openCircle()
            } else {
                self.handlers.restore()
            }
        }
    }
}
