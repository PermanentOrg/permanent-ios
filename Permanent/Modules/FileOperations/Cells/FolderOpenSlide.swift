//
//  FolderOpenSlide.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.09.2026.
//

import UIKit

/// Opening a folder as the back swipe mirrored: the list slides in from the trailing edge with the folder's loading
/// rows, over a snapshot of the rows it leaves, which drift a little the other way. The sort row stays put.
enum FolderOpenSlide {
    /// Runs `open`, which puts the folder's loading rows in the list, then slides the list in.
    /// With no window, no snapshot or Reduce Motion on, it only runs `open`.
    static func play(on list: UICollectionView, reduceMotion: Bool = UIAccessibility.isReduceMotionEnabled, _ open: () -> Void) {
        guard !reduceMotion, list.window != nil, let container = list.superview,
              let snapshot = list.snapshotView(afterScreenUpdates: false) else { return open() }
        let leftRows = UIView(frame: list.frame)
        snapshot.frame = leftRows.bounds
        leftRows.addSubview(snapshot)
        // The list clips to its bounds, so a view that moves with it casts its shadow.
        let shadow = UIView(frame: list.frame)
        shadow.backgroundColor = list.backgroundColor
        FolderBackSwipe.castEdgeShadow(from: shadow)
        let added = [leftRows, shadow]
        added.forEach {
            $0.isUserInteractionEnabled = false
            container.insertSubview($0, belowSubview: list)
        }
        // Before the list changes, so the row held still is the one on screen now.
        let heldRow = FolderBackSwipe.holdSortRow(of: list, above: list, in: container)

        open()
        list.layoutIfNeeded()
        // The list's cross-fade to the loading rows would slide the old rows in again.
        list.layer.removeAnimation(forKey: kCATransition)
        let sortRow = FolderBackSwipe.keepSortRow(heldRow, over: list, in: container)

        let direction: CGFloat = list.effectiveUserInterfaceLayoutDirection == .rightToLeft ? -1 : 1
        let width = list.bounds.width
        let offScreen = CGAffineTransform(translationX: width * direction, y: 0)
        list.transform = offScreen
        shadow.transform = offScreen
        UIView.animate(withDuration: FolderBackSwipe.duration, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            list.transform = .identity
            shadow.transform = .identity
            leftRows.transform = CGAffineTransform(translationX: -FolderBackSwipe.parallax * width * direction, y: 0)
        } completion: { _ in
            added.forEach { $0.removeFromSuperview() }
            FolderBackSwipe.releaseSortRow(sortRow)
        }
    }
}
