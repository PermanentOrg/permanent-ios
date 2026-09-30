//
//  StickyHeaderFlowLayoutTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 29.09.2026.
//

import XCTest
@testable import Permanent

final class StickyHeaderFlowLayoutTests: XCTestCase {
    private static let header = UICollectionView.elementKindSectionHeader
    private static let syncedPath = IndexPath(item: 0, section: 2)
    /// The Uploads header and its 2 rows of 74pt.
    private static let slotTop: CGFloat = 188

    private func makeList(_ configure: (StickyHeaderTestList) -> Void = { _ in }) -> (StickyHeaderTestList, StickyHeaderFlowLayout) {
        let layout = StickyHeaderFlowLayout.fileList()
        let list = StickyHeaderTestList(layout: layout)
        configure(list)
        list.reloadData()
        list.scroll(to: 0)
        return (list, layout)
    }

    /// The frame without the slide, as the row rests before its transform.
    private func restingFrame(_ attributes: UICollectionViewLayoutAttributes?) throws -> CGRect {
        let attributes = try XCTUnwrap(attributes)
        let size = attributes.size
        return CGRect(x: attributes.center.x - size.width / 2, y: attributes.center.y - size.height / 2, width: size.width, height: size.height)
    }

    /// A flow layout with the folder list's spacing and no pinning, to compare against.
    private func makePlainList(_ configure: (StickyHeaderTestList) -> Void = { _ in }) -> StickyHeaderTestList {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 0
        layout.estimatedItemSize = .zero
        let list = StickyHeaderTestList(layout: layout)
        configure(list)
        list.reloadData()
        return list
    }

    private func host(_ list: StickyHeaderTestList) -> UIWindow {
        let window = UIWindow(frame: list.frame)
        window.addSubview(list)
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
        return window
    }

    private func syncedHeaders(in elements: [UICollectionViewLayoutAttributes]?) -> [UICollectionViewLayoutAttributes] {
        (elements ?? []).filter {
            $0.representedElementCategory == .supplementaryView && $0.representedElementKind == Self.header && $0.indexPath == Self.syncedPath
        }
    }

    // MARK: - Pinning

    func testAtTheTop_TheSyncedHeaderSitsInItsSlotAboveTheRows() throws {
        let (list, layout) = makeList()

        let frame = try restingFrame(list.syncedHeader)
        XCTAssertEqual(frame.minY, Self.slotTop)
        XCTAssertEqual(frame.height, 40)
        XCTAssertEqual(list.syncedHeader?.zIndex, 1)
        XCTAssertEqual(layout.stickyHeaderSlot?.minY, Self.slotTop)
        XCTAssertEqual(layout.stickyHeaderSlot?.maxY, Self.slotTop + 40)
    }

    func testDeepInTheList_TheSyncedHeaderPinsToTheTopOverTheRows() throws {
        let (list, layout) = makeList()

        list.scroll(to: 600)

        XCTAssertEqual(try restingFrame(list.syncedHeader).minY, 600)
        XCTAssertEqual(list.syncedHeader?.zIndex, 1)
        XCTAssertEqual(list.syncedHeader?.alpha, 1)
        XCTAssertEqual(layout.stickyHeaderSlot?.minY, Self.slotTop, "the slot stays where the row rests")
    }

    func testTheSyncedHeader_SpansTheWholeListWidthInItsSlotAndPinned() throws {
        let (list, layout) = makeList()

        XCTAssertEqual(try restingFrame(list.syncedHeader).minX, -6)
        XCTAssertEqual(try restingFrame(list.syncedHeader).width, 390)
        XCTAssertEqual(layout.stickyHeaderSlot?.minX, -6)
        XCTAssertEqual(layout.stickyHeaderSlot?.width, 390)

        list.scroll(to: 600)
        XCTAssertEqual(try restingFrame(list.syncedHeader).minX, -6)
        XCTAssertEqual(try restingFrame(list.syncedHeader).width, 390)
    }

    func testAWidthChange_KeepsTheRowAtTheNewFullWidth() throws {
        let (list, _) = makeList()
        list.scroll(to: 600)

        list.frame.size.width = 375
        list.layoutIfNeeded()

        XCTAssertEqual(try restingFrame(list.syncedHeader).width, 375)
    }

    func testTheUploadsHeader_KeepsTheFrameAPlainFlowLayoutGivesIt() throws {
        let (list, _) = makeList()
        let plain = makePlainList()
        let uploadsPath = IndexPath(item: 0, section: 1)

        list.scroll(to: 600)
        plain.scroll(to: 600)

        let pinned = try XCTUnwrap(list.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: Self.header, at: uploadsPath))
        let natural = try XCTUnwrap(plain.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: Self.header, at: uploadsPath))
        XCTAssertEqual(pinned.frame, natural.frame)
        XCTAssertEqual(pinned.frame.minY, 0)
        XCTAssertEqual(pinned.zIndex, natural.zIndex)
    }

    func testTheRows_KeepTheFramesAPlainFlowLayoutGivesThem() throws {
        let (list, _) = makeList()
        let plain = makePlainList()
        list.scroll(to: 600)
        plain.scroll(to: 600)

        for item in [0, 7, 29] {
            let path = IndexPath(item: item, section: 2)
            XCTAssertEqual(list.collectionViewLayout.layoutAttributesForItem(at: path)?.frame, plain.collectionViewLayout.layoutAttributesForItem(at: path)?.frame)
        }
    }

    // MARK: - Hidden

    func testHidden_FadesThePinnedRowAndSlidesItUpOutOfTheList() throws {
        let (list, layout) = makeList()
        list.scroll(to: 600)

        layout.hidesStickyHeader = true
        list.layoutIfNeeded()

        let header = try XCTUnwrap(list.syncedHeader)
        XCTAssertEqual(header.alpha, 0)
        XCTAssertEqual(header.transform, CGAffineTransform(translationX: 0, y: -39), "a point short, so the view stays in the list")
        XCTAssertEqual(try restingFrame(header).minY, 600, "the row slides from where it is pinned")
        XCTAssertGreaterThan(header.frame.maxY, list.bounds.minY)
    }

    func testHiddenWithoutSliding_OnlyFades() throws {
        let (list, layout) = makeList()
        list.scroll(to: 600)

        layout.slidesStickyHeader = false
        layout.hidesStickyHeader = true
        list.layoutIfNeeded()

        XCTAssertEqual(list.syncedHeader?.alpha, 0)
        XCTAssertEqual(list.syncedHeader?.transform, .identity)
    }

    func testHidden_HasNoEffectWhileTheRowSitsInItsSlot() throws {
        let (list, layout) = makeList()
        layout.hidesStickyHeader = true

        for offset in [0, Self.slotTop] {
            list.scroll(to: offset)
            XCTAssertEqual(list.syncedHeader?.alpha, 1, "offset \(offset)")
            XCTAssertEqual(list.syncedHeader?.transform, .identity, "offset \(offset)")
        }
        list.scroll(to: Self.slotTop + 1)
        XCTAssertEqual(list.syncedHeader?.alpha, 0)
    }

    func testShowingAgain_BringsTheRowBackWhole() throws {
        let (list, layout) = makeList()
        list.scroll(to: 600)
        layout.hidesStickyHeader = true
        list.layoutIfNeeded()

        layout.hidesStickyHeader = false
        list.layoutIfNeeded()

        XCTAssertEqual(list.syncedHeader?.alpha, 1)
        XCTAssertEqual(list.syncedHeader?.transform, .identity)
    }

    // MARK: - No row

    func testAZeroHeightSyncedHeader_IsNotPinned() {
        let (list, layout) = makeList { $0.syncedHeaderHeight = 0 }
        let plain = makePlainList { $0.syncedHeaderHeight = 0 }

        layout.hidesStickyHeader = true
        list.scroll(to: 600)
        plain.scroll(to: 600)

        XCTAssertNil(layout.stickyHeaderSlot)
        XCTAssertEqual(list.syncedHeader?.frame, plain.syncedHeader?.frame)
        XCTAssertNotEqual(list.syncedHeader?.alpha, 0)
        XCTAssertTrue(syncedHeaders(in: layout.layoutAttributesForElements(in: list.bounds)).isEmpty)
    }

    func testWithoutASyncedSection_TogglingHiddenDoesNotCrash() {
        let (list, layout) = makeList { $0.sectionCount = 2 }

        layout.hidesStickyHeader = true
        list.layoutIfNeeded()
        layout.slidesStickyHeader = false
        layout.hidesStickyHeader = false
        list.layoutIfNeeded()

        XCTAssertNil(layout.stickyHeaderSlot)
        XCTAssertTrue(syncedHeaders(in: layout.layoutAttributesForElements(in: list.bounds)).isEmpty)
    }

    // MARK: - Elements in a rect

    func testTheVisibleRectFarBelowTheSlot_HoldsThePinnedHeaderOnce() throws {
        let (list, layout) = makeList()
        list.scroll(to: 1500)

        let headers = syncedHeaders(in: layout.layoutAttributesForElements(in: list.bounds))

        XCTAssertEqual(headers.count, 1)
        XCTAssertEqual(try restingFrame(headers.first).minY, 1500)
        XCTAssertEqual(headers.first?.zIndex, 1)
    }

    func testARectCoveringSlotAndPin_HoldsTheHeaderOnce() throws {
        let (list, layout) = makeList()
        list.scroll(to: 600)

        let headers = syncedHeaders(in: layout.layoutAttributesForElements(in: CGRect(x: 0, y: 0, width: 390, height: 3000)))

        XCTAssertEqual(headers.count, 1)
        XCTAssertEqual(try restingFrame(headers.first).minY, 600)
    }

    func testARectAroundTheSlotOnly_LeavesThePinnedHeaderOut() {
        let (list, layout) = makeList()
        list.scroll(to: 600)

        let headers = syncedHeaders(in: layout.layoutAttributesForElements(in: CGRect(x: 0, y: 150, width: 390, height: 100)))

        XCTAssertTrue(headers.isEmpty)
    }

    func testAHiddenSlidingRow_StillCountsAsInTheVisibleRect() throws {
        let (list, layout) = makeList()
        list.scroll(to: 600)
        layout.hidesStickyHeader = true

        let headers = syncedHeaders(in: layout.layoutAttributesForElements(in: list.bounds))

        XCTAssertEqual(headers.count, 1)
        XCTAssertEqual(headers.first?.alpha, 0)
    }

    // MARK: - Invalidation

    func testFileList_KeepsTheFolderListSpacingAndNoNativePinning() {
        let layout = StickyHeaderFlowLayout.fileList()

        XCTAssertEqual(layout.minimumInteritemSpacing, 6)
        XCTAssertEqual(layout.minimumLineSpacing, 0)
        XCTAssertEqual(layout.estimatedItemSize, .zero)
        XCTAssertEqual(layout.sectionInset, .zero)
        XCTAssertFalse(layout.sectionHeadersPinToVisibleBounds)
    }

    func testAScroll_InvalidatesOnlyThePinnedHeader() throws {
        let (list, layout) = makeList()
        let scrolled = list.bounds.offsetBy(dx: 0, dy: 300)

        XCTAssertTrue(layout.shouldInvalidateLayout(forBoundsChange: scrolled))
        let context = try XCTUnwrap(layout.invalidationContext(forBoundsChange: scrolled) as? UICollectionViewFlowLayoutInvalidationContext)

        XCTAssertFalse(context.invalidateFlowLayoutAttributes)
        XCTAssertFalse(context.invalidateFlowLayoutDelegateMetrics)
        XCTAssertEqual(context.invalidatedSupplementaryIndexPaths?[Self.header], [Self.syncedPath])
        XCTAssertNil(context.invalidatedItemIndexPaths)
    }

    func testAResize_AlsoInvalidatesThePinnedHeader() throws {
        let (list, layout) = makeList()
        var resized = list.bounds
        resized.size.width = 375

        let context = layout.invalidationContext(forBoundsChange: resized)

        XCTAssertEqual(context.invalidatedSupplementaryIndexPaths?[Self.header], [Self.syncedPath])
    }

    // MARK: - Hosted

    func testDuringARefresh_ThePinStaysAtTheOffset() throws {
        let (list, _) = makeList()
        _ = host(list)
        let refreshControl = UIRefreshControl()
        list.refreshControl = refreshControl
        list.layoutIfNeeded()

        refreshControl.beginRefreshing()
        list.scroll(to: 600)

        XCTAssertGreaterThan(list.adjustedContentInset.top, list.contentInset.top, "the spinner adds to the adjusted inset")
        XCTAssertEqual(try restingFrame(list.syncedHeader).minY, 600)
        refreshControl.endRefreshing()
    }

    func testAHiddenPinnedRow_KeepsItsViewInTheListAtAlphaZero() throws {
        let (list, layout) = makeList()
        _ = host(list)
        list.scroll(to: 600)

        layout.hidesStickyHeader = true
        list.layoutIfNeeded()

        let view = try XCTUnwrap(list.supplementaryView(forElementKind: Self.header, at: Self.syncedPath))
        XCTAssertTrue(list.visibleSupplementaryViews(ofKind: Self.header).contains(view))
        XCTAssertEqual(view.alpha, 0)
        XCTAssertEqual(view.frame.width, 390)
    }
}
