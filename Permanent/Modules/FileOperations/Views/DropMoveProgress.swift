//
//  DropMoveProgress.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.10.2026.
//

import Foundation

/// Counts the drop moves under way, so one progress circle covers them all, as after Move Here.
final class DropMoveProgress {
    enum Step: Equatable {
        case none
        case showSpinner
        case showCheck
        case close
    }

    private(set) var running = 0
    private var failed = false

    var isRunning: Bool { running > 0 }

    /// A move starts; the first one opens the circle.
    func begin() -> Step {
        running += 1
        return running == 1 ? .showSpinner : .none
    }

    /// A move ends; the last one shows the check, or closes the circle without it when any move failed.
    func end(succeeded: Bool) -> Step {
        guard running > 0 else { return .none }
        running -= 1
        if !succeeded { failed = true }
        guard running == 0 else { return .none }
        defer { failed = false }
        return failed ? .close : .showCheck
    }
}
