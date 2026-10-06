//
//  FolderHeaderTransition.swift
//  Permanent
//
//  Created by Lucian Cerbu on 23.09.2026.
//

import UIKit

/// The folder name and back arrow over a folder list. Keeps the header one height whether or not the arrow
/// shows, and fades the name and slides the arrow when the folder changes.
final class FolderHeaderTransition {
    private weak var backButton: UIButton?
    private weak var titleLabel: UILabel?

    private static let duration: TimeInterval = 0.25
    /// Where a running arrow animation is heading; during a fade-out `isHidden` still reads false.
    private var backTarget: Bool?
    private var backChange = 0
    /// Counts header changes, so a flow can tell whether anything else changed the header since it did.
    private(set) var revision = 0

    init(backButton: UIButton, titleLabel: UILabel) {
        self.backButton = backButton
        self.titleLabel = titleLabel
        // The arrow sets the header's height; a hidden arrow keeps its constraints, so the name holds it instead.
        if let row = titleLabel.superview, row === backButton.superview {
            titleLabel.heightAnchor.constraint(greaterThanOrEqualTo: backButton.heightAnchor).isActive = true
        }
    }

    /// The header as it is now, or is heading to, to put back if a navigation fails.
    var current: (title: String?, showsBack: Bool) {
        (titleLabel?.text, showsBack)
    }

    private var showsBack: Bool {
        backTarget ?? !(backButton?.isHidden ?? true)
    }

    func show(title: String?, showsBack newShowsBack: Bool, animated: Bool = true) {
        guard let backButton, let titleLabel else { return }
        let changesTitle = titleLabel.text != title
        let changesBack = showsBack != newShowsBack
        guard changesTitle || changesBack else { return }
        revision += 1
        if changesBack { backChange += 1 }
        guard animated, titleLabel.window != nil else {
            titleLabel.text = title
            if changesBack {
                backTarget = nil
                setBackHidden(!newShowsBack)
                backButton.alpha = newShowsBack ? visibleBackAlpha : 0
            }
            return
        }

        // Layout a list reload left pending must not ride along in the header's animation.
        let container = backButton.superview?.superview
        container?.layoutIfNeeded()

        if changesTitle {
            fadeTitle(of: titleLabel, to: title, followsLabel: changesBack && newShowsBack)
            // The new name takes its full width now, while it is hidden, so it never shows cut off.
            container?.layoutIfNeeded()
        }
        guard changesBack else { return }
        // Under Reduce Motion the arrow only fades; the name moves without sliding.
        let slides = !UIAccessibility.isReduceMotionEnabled
        let change = backChange
        backTarget = newShowsBack
        if newShowsBack {
            backButton.alpha = 0
            if !slides {
                setBackHidden(false)
                container?.layoutIfNeeded()
            }
        }
        UIView.animate(withDuration: Self.duration, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
            backButton.alpha = newShowsBack ? self.visibleBackAlpha : 0
            if slides {
                self.setBackHidden(!newShowsBack)
                container?.layoutIfNeeded()
            }
        } completion: { _ in
            // A newer change may have started meanwhile; only the latest one settles the arrow.
            guard change == self.backChange else { return }
            self.setBackHidden(!newShowsBack)
            self.backTarget = nil
        }
    }

    /// The old name fades out, then the new one fades in. Dissolved into each other, both names show at once,
    /// the old one clipped to the new one's width.
    private func fadeTitle(of label: UILabel, to title: String?, followsLabel: Bool) {
        let half = Self.duration / 2
        let old = label.snapshotView(afterScreenUpdates: false)
        if let old, let row = label.superview {
            old.isUserInteractionEnabled = false
            old.frame = label.frame
            row.addSubview(old)
            // As the arrow comes in, the old name moves aside with the label; as it goes, the old name stays clear of it.
            if followsLabel {
                old.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    old.leadingAnchor.constraint(equalTo: label.leadingAnchor),
                    old.centerYAnchor.constraint(equalTo: label.centerYAnchor),
                    old.widthAnchor.constraint(equalToConstant: label.bounds.width),
                    old.heightAnchor.constraint(equalToConstant: label.bounds.height)
                ])
            }
            UIView.animate(withDuration: half, delay: 0, options: [.curveEaseIn, .allowUserInteraction]) {
                old.alpha = 0
            } completion: { _ in
                old.removeFromSuperview()
            }
        }
        label.text = title
        label.alpha = 0
        UIView.animate(withDuration: half, delay: old == nil ? 0 : half, options: [.curveEaseOut, .allowUserInteraction]) {
            label.alpha = 1
        }
    }

    /// Select mode dims a disabled arrow instead of hiding it; a shown arrow keeps that look.
    private var visibleBackAlpha: CGFloat {
        (backButton?.isUserInteractionEnabled ?? true) ? 1 : 0.3
    }

    /// A stack view counts repeated hides, so only a real change is set.
    private func setBackHidden(_ hidden: Bool) {
        guard let backButton, backButton.isHidden != hidden else { return }
        backButton.isHidden = hidden
    }
}
