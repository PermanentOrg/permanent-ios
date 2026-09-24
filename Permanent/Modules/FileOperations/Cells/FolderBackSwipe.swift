//
//  FolderBackSwipe.swift
//  Permanent
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
    private let gesture = UIScreenEdgePanGestureRecognizer()
    private var slidingRows: UIView?
    private var dimming: UIView?
    private var savedOffset: CGPoint = .zero
    /// Plus one when the leading edge is the left one.
    private var direction: CGFloat = 1

    private static let parallax: CGFloat = 0.3
    private static let dimmingAlpha: CGFloat = 0.06
    private static let duration: TimeInterval = 0.25

    init(list: UICollectionView, in view: UIView, handlers: Handlers) {
        self.list = list
        self.handlers = handlers
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
        slidingRows == nil && handlers.canGoBack()
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
        rows.layer.shadowColor = UIColor.black.cgColor
        rows.layer.shadowOpacity = 0.15
        rows.layer.shadowRadius = 8
        // Kept off the top and bottom edges, so only the side that moves casts a shadow.
        rows.layer.shadowPath = UIBezierPath(rect: rows.bounds.insetBy(dx: 0, dy: rows.layer.shadowRadius)).cgPath

        let dimming = UIView(frame: list.frame)
        dimming.backgroundColor = UIColor.black.withAlphaComponent(Self.dimmingAlpha)
        dimming.isUserInteractionEnabled = false
        container.insertSubview(dimming, aboveSubview: list)
        container.insertSubview(rows, aboveSubview: dimming)
        slidingRows = rows
        self.dimming = dimming

        savedOffset = list.contentOffset
        handlers.showParentPreview()
        list.layoutIfNeeded()
    }

    private func move(to travel: CGFloat) {
        guard let list, let slidingRows else { return }
        let width = max(1, list.bounds.width)
        let progress = travel / width
        slidingRows.transform = CGAffineTransform(translationX: travel * direction, y: 0)
        dimming?.alpha = 1 - progress
        // The parent drifts in from a little behind, unless Reduce Motion is on.
        let drift = UIAccessibility.isReduceMotionEnabled ? 0 : -(1 - progress) * Self.parallax * width * direction
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
        dimming?.removeFromSuperview()
        slidingRows = nil
        dimming = nil
    }
}
