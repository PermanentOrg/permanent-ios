//
//  FolderBackSwipe.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.09.2026.
//

import UIKit

/// A swipe in from the leading edge that goes up one folder and follows the finger, as the iOS back swipe does.
/// The folder's rows slide off a snapshot, over the list already showing the parent's loading rows.
final class FolderBackSwipe: NSObject, UIGestureRecognizerDelegate {
    struct Handlers {
        /// Whether the back arrow could be tapped now.
        let canGoBack: () -> Bool
        /// Puts the list in the look the parent folder loads in.
        let showParentPreview: () -> Void
        /// Whether the folder the swipe began in is still on screen, with no other load under way.
        let previewStillApplies: () -> Bool
        /// `true` when the folder's own rows came back, as no other load started since.
        let endParentPreview: () -> Bool
        let goBack: () -> Void
    }

    private weak var list: UICollectionView?
    private let handlers: Handlers
    private let reduceMotion: () -> Bool
    private let gesture = UIScreenEdgePanGestureRecognizer()
    private var slidingRows: UIView?
    private var sortRow: UIView?
    private var savedOffset: CGPoint = .zero
    /// Plus one when the leading edge is the left one.
    private var direction: CGFloat = 1

    /// Opening a folder uses the same motion, mirrored.
    static let parallax: CGFloat = 0.3
    static let duration: TimeInterval = 0.25

    init(list: UICollectionView, in view: UIView, handlers: Handlers, reduceMotion: @escaping () -> Bool = { UIAccessibility.isReduceMotionEnabled }) {
        self.list = list
        self.handlers = handlers
        self.reduceMotion = reduceMotion
        super.init()
        let isRightToLeft = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
        direction = isRightToLeft ? -1 : 1
        gesture.edges = isRightToLeft ? .right : .left
        gesture.addTarget(self, action: #selector(handlePan(_:)))
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
        // A touch at the edge is a back swipe first; the list scrolls only once that has failed.
        list.panGestureRecognizer.require(toFail: gesture)
    }

    /// Past a third of the width, or flicked, it goes back; a flick the other way always springs back.
    static func goesBack(travel: CGFloat, speed: CGFloat, width: CGFloat) -> Bool {
        speed > 500 || (speed > -500 && travel > width / 3)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // A second finger at the edge during a drag must not swipe the folder away under the files.
        guard let list, !list.hasActiveDrag, !list.hasActiveDrop else { return false }
        return slidingRows == nil && handlers.canGoBack()
    }

    /// The back arrow's slide: the swipe played through on its own. `false` when there is nothing to slide,
    /// or Reduce Motion is on, and then the caller goes back without it.
    func slideBack() -> Bool {
        guard !reduceMotion(), slidingRows == nil, handlers.canGoBack(), let list, list.window != nil,
              let container = list.superview else { return false }
        begin(list, in: container)
        guard slidingRows != nil else { return false }
        move(to: 0)
        finish()
        // In the same turn as the preview, the load's cross-fade would start from the folder's own rows.
        list.layer.removeAnimation(forKey: kCATransition)
        return true
    }

    /// The sort row as it shows now, held still above the sliding rows, as a bar stays put over a page.
    /// Nil when the row is hidden or there is none, and then it slides with the rows.
    static func holdSortRow(of list: UICollectionView, above view: UIView, in container: UIView) -> UIView? {
        guard let frame = (list.collectionViewLayout as? StickyHeaderFlowLayout)?.shownStickyHeaderFrame,
              let still = list.resizableSnapshotView(from: frame, afterScreenUpdates: false, withCapInsets: .zero) else { return nil }
        still.frame = list.convert(frame, to: container)
        still.isUserInteractionEnabled = false
        container.insertSubview(still, aboveSubview: view)
        return still
    }

    /// Once the list shows the next folder, the held row stays only if that folder's own row sits in the same place.
    static func keepSortRow(_ still: UIView?, over list: UICollectionView, in container: UIView) -> UIView? {
        guard let still else { return nil }
        guard let frame = (list.collectionViewLayout as? StickyHeaderFlowLayout)?.shownStickyHeaderFrame,
              abs(list.convert(frame, to: container).minY - still.frame.minY) < 1, abs(frame.height - still.frame.height) < 1 else {
            still.removeFromSuperview()
            return nil
        }
        return still
    }

    /// Hands over to the list's own row. A sort that changed fades in; the same sort shows no change.
    static func releaseSortRow(_ still: UIView?) {
        guard let still else { return }
        UIView.animate(withDuration: sortRowFade, delay: 0, options: [.allowUserInteraction]) {
            still.alpha = 0
        } completion: { _ in
            still.removeFromSuperview()
        }
    }

    static let sortRowFade: TimeInterval = 0.15

    /// The shadow the moving rows cast on the rows they cover.
    static func castEdgeShadow(from view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowRadius = 8
        // A blur reaches about twice its radius. Unshifted and inset that far, only the side that moves casts a
        // shadow, and none spills onto the sort row or the folder name above it.
        view.layer.shadowOffset = .zero
        view.layer.shadowPath = UIBezierPath(rect: view.bounds.insetBy(dx: 0, dy: 2 * view.layer.shadowRadius)).cgPath
    }

    @objc private func handlePan(_ pan: UIScreenEdgePanGestureRecognizer) {
        guard let list, let container = list.superview else { return }
        let width = list.bounds.width
        let travel = min(width, max(0, pan.translation(in: container).x * direction))
        switch pan.state {
        case .began:
            begin(list, in: container)
            move(to: travel)
        case .changed:
            move(to: travel)
        case .ended:
            let speed = pan.velocity(in: container).x * direction
            // Something may have changed the folder under the finger, and then going back would undo it.
            Self.goesBack(travel: travel, speed: speed, width: width) && handlers.previewStillApplies() ? finish() : springBack()
        case .cancelled, .failed:
            springBack()
        default:
            break
        }
    }

    private func begin(_ list: UICollectionView, in container: UIView) {
        guard let snapshot = list.snapshotView(afterScreenUpdates: false) else { return }
        let rows = UIView(frame: list.frame)
        snapshot.frame = rows.bounds
        rows.addSubview(snapshot)
        Self.castEdgeShadow(from: rows)
        container.insertSubview(rows, aboveSubview: list)
        // Before the parent's look, so the row held still is this folder's own.
        let heldRow = Self.holdSortRow(of: list, above: rows, in: container)
        slidingRows = rows

        savedOffset = list.contentOffset
        handlers.showParentPreview()
        list.layoutIfNeeded()
        sortRow = Self.keepSortRow(heldRow, over: list, in: container)
    }

    private func move(to travel: CGFloat) {
        guard let list, let slidingRows else { return }
        let width = max(1, list.bounds.width)
        let progress = travel / width
        slidingRows.transform = CGAffineTransform(translationX: travel * direction, y: 0)
        // The parent drifts in from a little behind, unless Reduce Motion is on.
        let drift = reduceMotion() ? 0 : -(1 - progress) * Self.parallax * width * direction
        list.transform = CGAffineTransform(translationX: drift, y: 0)
    }

    private func finish() {
        guard let list, slidingRows != nil else { return }
        // The real load starts before the preview ends, so the parent's loading rows never blink.
        handlers.goBack()
        _ = handlers.endParentPreview()
        UIView.animate(withDuration: Self.duration, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.move(to: list.bounds.width)
        } completion: { _ in
            self.tearDown()
        }
    }

    private func springBack() {
        guard let list, slidingRows != nil else { return }
        UIView.animate(withDuration: Self.duration, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            self.move(to: 0)
        } completion: { _ in
            // Under the snapshot, so the rows come back where they were before it lifts.
            if self.handlers.endParentPreview() {
                list.layoutIfNeeded()
                list.contentOffset = Self.clamped(self.savedOffset, in: list)
            }
            self.tearDown()
        }
    }

    /// A refresh or a shorter listing during the drag can leave the old offset out of range.
    private static func clamped(_ offset: CGPoint, in list: UIScrollView) -> CGPoint {
        let inset = list.adjustedContentInset
        let top = -inset.top
        let bottom = max(top, list.contentSize.height + inset.bottom - list.bounds.height)
        return CGPoint(x: offset.x, y: min(max(offset.y, top), bottom))
    }

    private func tearDown() {
        list?.transform = .identity
        slidingRows?.removeFromSuperview()
        Self.releaseSortRow(sortRow)
        slidingRows = nil
        sortRow = nil
    }
}
