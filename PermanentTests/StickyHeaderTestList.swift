//
//  StickyHeaderTestList.swift
//  PermanentTests
//

import UIKit
@testable import Permanent

/// A 390 x 844pt folder list with the screens' sections: Downloads (empty), Uploads (2 rows) and the synced list
/// (30 rows of 74pt), each non-empty one under a header (40pt unless set), then an empty paging section.
final class StickyHeaderTestList: UICollectionView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    static let rowHeight: CGFloat = 74
    static let headerHeight: CGFloat = 40
    static let cellId = "row"
    static let headerId = "header"

    var sectionCount = 4
    var uploadRows = 2
    var syncedRows = 30
    var uploadsHeaderHeight = StickyHeaderTestList.headerHeight
    var syncedHeaderHeight = StickyHeaderTestList.headerHeight

    private var fingerDrags = false
    private var fingerFlung = false

    override var isDragging: Bool {
        get { fingerDrags }
        set { fingerDrags = newValue }
    }

    override var isDecelerating: Bool {
        get { fingerFlung }
        set { fingerFlung = newValue }
    }

    init(layout: UICollectionViewLayout = StickyHeaderFlowLayout.fileList()) {
        super.init(frame: CGRect(x: 0, y: 0, width: 390, height: 844), collectionViewLayout: layout)
        // The folder screens' insets: 6pt sides and blank room under the last row.
        contentInset = UIEdgeInsets(top: 0, left: 6, bottom: 350, right: 6)
        register(UICollectionViewCell.self, forCellWithReuseIdentifier: Self.cellId)
        register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Self.headerId)
        dataSource = self
        delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Scrolls to `y` as the folder screens sit, with the content's left edge at the side inset.
    func scroll(to y: CGFloat) {
        contentOffset = CGPoint(x: -contentInset.left, y: y)
        layoutIfNeeded()
    }

    var syncedHeader: UICollectionViewLayoutAttributes? {
        collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 2))
    }

    private func rows(in section: Int) -> Int {
        switch section {
        case 1: return uploadRows
        case 2: return syncedRows
        default: return 0
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sectionCount
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        rows(in: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellId, for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: Self.headerId, for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: bounds.width - contentInset.left - contentInset.right, height: Self.rowHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let height = section == 2 ? syncedHeaderHeight : uploadsHeaderHeight
        return CGSize(width: bounds.width, height: rows(in: section) > 0 ? height : 0)
    }
}
