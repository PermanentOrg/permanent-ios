//
//  StickyHeaderFlowLayout.swift
//  Permanent
//

import UIKit

/// The folder list's flow layout. It pins the synced section's header, the sort and Select row, to the list's top
/// so rows scroll under it; the Downloads and Uploads headers scroll away as usual.
final class StickyHeaderFlowLayout: UICollectionViewFlowLayout {
    private static let headerKind = UICollectionView.elementKindSectionHeader
    private static let stickyPath = IndexPath(item: 0, section: FileListType.synced.rawValue)

    /// The spacing every folder list uses, in list and in grid.
    static func fileList() -> StickyHeaderFlowLayout {
        let layout = StickyHeaderFlowLayout()
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 0
        layout.estimatedItemSize = .zero
        return layout
    }

    /// Hidden is alpha 0, slid up out of the list unless `slidesStickyHeader` is off.
    var hidesStickyHeader = false {
        didSet { if hidesStickyHeader != oldValue { invalidateStickyHeader() } }
    }

    var slidesStickyHeader = true {
        didSet { if slidesStickyHeader != oldValue, hidesStickyHeader { invalidateStickyHeader() } }
    }

    /// Where the row sits when the list is at its top, across the list's full width; nil when there is no row.
    var stickyHeaderSlot: CGRect? {
        naturalStickyHeader().map { fullWidth($0.frame) }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        guard let pinned = pinnedStickyHeader() else { return attributes }
        var elements = (attributes ?? []).filter { !Self.isStickyHeader($0) }
        if Self.restingFrame(of: pinned).intersects(rect) { elements.append(pinned) }
        return elements
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == Self.headerKind, indexPath == Self.stickyPath, let pinned = pinnedStickyHeader() {
            return pinned
        }
        return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }

    /// A scroll moves only the pinned row, so the rows keep their cached frames even in a folder listed whole.
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        guard let collectionView, hasStickySection else { return context }
        if newBounds.size == collectionView.bounds.size, let flowContext = context as? UICollectionViewFlowLayoutInvalidationContext {
            flowContext.invalidateFlowLayoutAttributes = false
            flowContext.invalidateFlowLayoutDelegateMetrics = false
        }
        context.invalidateSupplementaryElements(ofKind: Self.headerKind, at: [Self.stickyPath])
        return context
    }

    // MARK: - Pinned copy

    private var hasStickySection: Bool {
        (collectionView?.numberOfSections ?? 0) > Self.stickyPath.section
    }

    private static func isStickyHeader(_ attributes: UICollectionViewLayoutAttributes) -> Bool {
        attributes.representedElementCategory == .supplementaryView
            && attributes.representedElementKind == headerKind
            && attributes.indexPath == stickyPath
    }

    /// The frame before the slide, so a row sliding away still counts as on screen and keeps its view.
    private static func restingFrame(of attributes: UICollectionViewLayoutAttributes) -> CGRect {
        let size = attributes.size
        return CGRect(x: attributes.center.x - size.width / 2, y: attributes.center.y - size.height / 2, width: size.width, height: size.height)
    }

    /// Super's own attributes for the row, or nil when the section is missing or the row is 0pt high.
    private func naturalStickyHeader() -> UICollectionViewLayoutAttributes? {
        guard hasStickySection,
              let attributes = super.layoutAttributesForSupplementaryView(ofKind: Self.headerKind, at: Self.stickyPath),
              attributes.frame.height > 0 else { return nil }
        return attributes
    }

    /// Covers the side gutters too, so rows passing under the row never show beside it.
    private func fullWidth(_ frame: CGRect) -> CGRect {
        guard let collectionView else { return frame }
        return CGRect(x: -collectionView.contentInset.left, y: frame.minY, width: collectionView.bounds.width, height: frame.height)
    }

    private func pinnedStickyHeader() -> UICollectionViewLayoutAttributes? {
        guard let collectionView,
              let natural = naturalStickyHeader(),
              let pinned = natural.copy() as? UICollectionViewLayoutAttributes else { return nil }
        let slot = fullWidth(natural.frame)
        // Not the adjusted inset, which grows by the refresh control's height while it spins.
        let top = collectionView.contentOffset.y + collectionView.contentInset.top
        pinned.frame = CGRect(x: slot.minX, y: max(slot.minY, top), width: slot.width, height: slot.height)
        pinned.zIndex = 1
        if hidesStickyHeader, top > slot.minY {
            pinned.alpha = 0
            // A point short of the height: a frame wholly above the list's bounds would lose its view mid-animation.
            let slide = max(0, slot.height - 1)
            pinned.transform = slidesStickyHeader ? CGAffineTransform(translationX: 0, y: -slide) : .identity
        }
        return pinned
    }

    private func invalidateStickyHeader() {
        guard hasStickySection else {
            invalidateLayout()
            return
        }
        let context = UICollectionViewFlowLayoutInvalidationContext()
        context.invalidateFlowLayoutAttributes = false
        context.invalidateFlowLayoutDelegateMetrics = false
        context.invalidateSupplementaryElements(ofKind: Self.headerKind, at: [Self.stickyPath])
        invalidateLayout(with: context)
    }
}
