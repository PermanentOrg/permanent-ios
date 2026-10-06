//
//  FileListPagingSection.swift
//  Permanent
//
//  Created by Lucian Cerbu on 23.09.2026.
//

import UIKit

/// The extra last section of a folder list: skeleton rows while pages load, and the status footer under them.
/// Screens forward their data-source and layout calls for `sectionIndex` here.
final class FileListPagingSection {
    private weak var collectionView: UICollectionView?
    private let viewModel: () -> FilesViewModel?
    private let onChange: () -> Void
    private var observers: [NSObjectProtocol] = []
    private var pendingFadeDuration: CFTimeInterval?
    private var skeletonShownAt: CFTimeInterval?
    /// While `onChange` runs for a later page, the index of its first row; that page only adds rows after the listed ones.
    private var addedPageStart: Int?
    var isAddingPage: Bool { addedPageStart != nil }

    private static let skeletonFadeIn: CFTimeInterval = 0.2
    private static let skeletonFadeOut: CFTimeInterval = 0.3
    /// Long enough for the placeholders to read as a step rather than a flicker when a page comes back at once.
    private static let skeletonMinimumTime: CFTimeInterval = 0.4

    private static let firstPageListRows = 8
    private static let firstPageGridTiles = 6
    /// Under a failed page's retry footer, and while the list has no size yet.
    private static let fewListRows = 3
    private static let fewGridTiles = 2
    /// How far ahead of the end rows ask for the next page, so it lands before a brisk scroll reaches the skeleton rows.
    private static let prefetchScreens = 2

    /// `onChange` redraws the whole screen, empty-folder view included, after a page lands anywhere.
    init(collectionView: UICollectionView, viewModel: @escaping () -> FilesViewModel?, onChange: @escaping () -> Void) {
        self.collectionView = collectionView
        self.viewModel = viewModel
        self.onChange = onChange
        collectionView.register(FileSkeletonCollectionViewCell.self, forCellWithReuseIdentifier: FileSkeletonCollectionViewCell.identifier)
        collectionView.register(FileListStatusFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: FileListStatusFooterView.identifier)

        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: FilesViewModel.childrenDidChangeNotification, object: nil, queue: .main) { [weak self] notification in
            guard let self, let viewModel = self.viewModel(), notification.object as? FilesViewModel === viewModel else { return }
            let focusWasOnPlaceholder = UIAccessibility.focusedElement(using: .notificationVoiceOver) is FileSkeletonCollectionViewCell
            let firstNewChild = notification.userInfo?[FilesViewModel.firstNewChildKey] as? Int
            self.addedPageStart = firstNewChild
            self.onChange()
            self.addedPageStart = nil
            if let firstNewChild {
                self.fadeInRows(from: firstNewChild)
                // The first new row takes the placeholder's place, so VoiceOver carries on from there.
                if focusWasOnPlaceholder {
                    self.moveAccessibilityFocus(to: self.collectionView?.cellForItem(at: IndexPath(item: firstNewChild, section: self.sectionIndex - 1)))
                }
            }
            // After the redraw, so focus lands on the error and its retry button instead of a row that went silent.
            if viewModel.childrenPagingState == .failed, !viewModel.isLoadingFirstPage {
                self.showFooterToVoiceOver()
            }
        })
        observers.append(center.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.collectionView?.collectionViewLayout.invalidateLayout()
        })
        DispatchQueue.main.async { FileListStatusFooterView.prepareSizing() }
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    /// Right after the view model's own sections.
    var sectionIndex: Int { viewModel()?.numberOfSections ?? 0 }

    func numberOfItems(isGrid: Bool) -> Int {
        guard let viewModel = viewModel() else { return 0 }
        if viewModel.isLoadingFirstPage {
            return isGrid ? Self.firstPageGridTiles : Self.firstPageListRows
        }
        switch viewModel.childrenPagingState {
        case .complete: return 0
        case .loadingMore: return nextPagePlaceholders(isGrid: isGrid)
        // A few, so the retry footer stays close to the rows.
        case .failed: return isGrid ? Self.fewGridTiles : Self.fewListRows
        }
    }

    /// Enough placeholders to fill the list's height, up to one page; the server sends no count of what is left.
    /// The count follows the height, so a batch update must reconcile this section, as `insertAddedPage()` does.
    private func nextPagePlaceholders(isGrid: Bool) -> Int {
        let few = isGrid ? Self.fewGridTiles : Self.fewListRows
        guard let itemsPerScreen else { return few }
        return max(few, min(itemsPerScreen, FilesViewModel.nextChildrenPageSize))
    }

    /// How many rows or tiles fill the list's height, or nil while the list has no size yet.
    private var itemsPerScreen: Int? {
        guard let collectionView, collectionView.bounds.height > 0,
              let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return nil }
        let size = (collectionView.delegate as? UICollectionViewDelegateFlowLayout)?
            .collectionView?(collectionView, layout: layout, sizeForItemAt: IndexPath(item: 0, section: sectionIndex)) ?? layout.itemSize
        guard size.width > 0, size.height > 0 else { return nil }
        let width = collectionView.bounds.width - layout.sectionInset.left - layout.sectionInset.right
        let perLine = max(1, Int((width + layout.minimumInteritemSpacing) / (size.width + layout.minimumInteritemSpacing)))
        let lines = Int((collectionView.bounds.height / (size.height + layout.minimumLineSpacing)).rounded(.up))
        return perLine * lines
    }

    func cell(at indexPath: IndexPath, isGrid: Bool) -> UICollectionViewCell {
        guard let collectionView,
              let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileSkeletonCollectionViewCell.identifier, for: indexPath) as? FileSkeletonCollectionViewCell else {
            return UICollectionViewCell()
        }
        // One placeholder speaks for the rest, so VoiceOver can tell the list goes on.
        let label = indexPath.item == 0 ? accessibilityLabelForSkeleton : nil
        // Under the retry footer nothing is loading, so the placeholders hold still.
        let isLoading = viewModel().map { $0.isLoadingFirstPage || $0.childrenPagingState == .loadingMore } ?? false
        cell.configure(isGrid: isGrid, accessibilityLabel: label, shimmers: isLoading)
        return cell
    }

    private var accessibilityLabelForSkeleton: String? {
        guard let viewModel = viewModel() else { return nil }
        if viewModel.isLoadingFirstPage { return "LoadingItems".localized() }
        return viewModel.childrenPagingState == .loadingMore ? "LoadingMoreItems".localized() : nil
    }

    var footerContent: FileListStatusFooterView.Content {
        guard let viewModel = viewModel(), !viewModel.isLoadingFirstPage, viewModel.currentFolder != nil else { return .hidden }
        switch viewModel.childrenPagingState {
        case .failed: return .failed
        case .loadingMore: return .hidden
        case .complete:
            guard !viewModel.syncedViewModels.isEmpty else { return .hidden }
            return .counts(folders: viewModel.loadedFolderCount, files: viewModel.loadedFileCount)
        }
    }

    func footer(at indexPath: IndexPath) -> UICollectionReusableView {
        guard let collectionView,
              let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: FileListStatusFooterView.identifier, for: indexPath) as? FileListStatusFooterView else {
            return UICollectionReusableView()
        }
        footer.configure(footerContent)
        footer.retryAction = { [weak self] in self?.retry() }
        return footer
    }

    func retry() {
        viewModel()?.retryNextChildrenPage { _ in }
        onChange()
        // The focused retry button is gone now; the first placeholder says more is loading.
        moveAccessibilityFocus(to: collectionView?.cellForItem(at: IndexPath(item: 0, section: sectionIndex)))
    }

    /// The footer sits under the placeholders and is often off screen when a page fails, so it is scrolled in first.
    private func showFooterToVoiceOver() {
        guard UIAccessibility.isVoiceOverRunning, let collectionView else { return }
        collectionView.layoutIfNeeded()
        let footerPath = IndexPath(item: 0, section: sectionIndex)
        if let frame = collectionView.layoutAttributesForSupplementaryElement(ofKind: UICollectionView.elementKindSectionFooter, at: footerPath)?.frame {
            collectionView.scrollRectToVisible(frame, animated: false)
        }
        moveAccessibilityFocus(to: visibleFooter)
    }

    private var visibleFooter: UIView? {
        collectionView?.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: sectionIndex))
    }

    private func moveAccessibilityFocus(to view: @autoclosure () -> UIView?) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        collectionView?.layoutIfNeeded()
        UIAccessibility.post(notification: .layoutChanged, argument: view())
    }

    func footerSize(width: CGFloat) -> CGSize {
        let traits = collectionView?.traitCollection ?? UITraitCollection.current
        return CGSize(width: width, height: FileListStatusFooterView.height(for: footerContent, width: width, traits: traits))
    }

    // MARK: - Fades

    /// The next reload cross-fades from the old rows to the skeleton rows.
    func skeletonWillAppear() {
        pendingFadeDuration = Self.skeletonFadeIn
        skeletonShownAt = CACurrentMediaTime()
    }

    /// The next reload cross-fades from the skeleton rows to the folder's rows.
    func skeletonWillDisappear() {
        pendingFadeDuration = Self.skeletonFadeOut
    }

    /// Runs `work` once the skeleton has been up for its minimum time. At once off screen, as in tests.
    func afterSkeletonMinimumTime(_ work: @escaping () -> Void) {
        let shownAt = skeletonShownAt
        skeletonShownAt = nil
        guard let shownAt, collectionView?.window != nil else { return work() }
        let wait = Self.skeletonMinimumTime - (CACurrentMediaTime() - shownAt)
        guard wait > 0 else { return work() }
        DispatchQueue.main.asyncAfter(deadline: .now() + wait, execute: work)
    }

    /// Screens call this right before `reloadData`, so a pending fade covers exactly that change.
    func prepareForReload() {
        guard let duration = pendingFadeDuration, let collectionView else { return }
        pendingFadeDuration = nil
        let fade = CATransition()
        fade.type = .fade
        fade.duration = duration
        fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        collectionView.layer.add(fade, forKey: kCATransition)
    }

    /// A later page lands while the list may be scrolling, so only its new rows fade in, not the whole list.
    private func fadeInRows(from firstNewItem: Int) {
        guard let collectionView, sectionIndex > 0 else { return }
        collectionView.layoutIfNeeded()
        let rowsSection = sectionIndex - 1
        let newCells = collectionView.visibleCells.filter { cell in
            guard let indexPath = collectionView.indexPath(for: cell) else { return false }
            return indexPath.section == rowsSection && indexPath.item >= firstNewItem
        }
        guard !newCells.isEmpty else { return }
        newCells.forEach { $0.alpha = 0 }
        UIView.animate(withDuration: 0.25, delay: 0, options: [.allowUserInteraction, .curveEaseOut]) {
            newCells.forEach { $0.alpha = 1 }
        }
    }

    /// Rows within two screens of the end, and the skeleton rows, ask for the next page as they come into view. Driven
    /// by display rather than scroll offset, since the public archive tab rewrites `contentOffset` for its parent page.
    func willDisplayItem(at indexPath: IndexPath) {
        guard let viewModel = viewModel(), !viewModel.isLoadingFirstPage, viewModel.childrenPagingState == .loadingMore else { return }
        let rowsSection = sectionIndex - 1
        let isNearTheEnd = indexPath.section == rowsSection
            && indexPath.item >= viewModel.numberOfRowsInSection(rowsSection) - Self.prefetchScreens * (itemsPerScreen ?? 0)
        guard indexPath.section == sectionIndex || isNearTheEnd else { return }
        viewModel.loadNextChildrenPage { _ in }
    }

    /// Adds a later page's rows and leaves the rows on screen as they are. Screens call it from `onChange`; on false, as off
    /// screen, in select mode, for a list left empty or after another change to the list, they reload the list whole.
    func insertAddedPage() -> Bool {
        guard let first = addedPageStart, let collectionView, collectionView.window != nil,
              let dataSource = collectionView.dataSource, viewModel()?.isSelecting == false else { return false }
        let rowsSection = sectionIndex - 1
        let sectionCount = dataSource.numberOfSections?(in: collectionView) ?? 1
        guard rowsSection >= 0, sectionCount == sectionIndex + 1, collectionView.numberOfSections == sectionCount else { return false }
        // The list's counts are from before the page; the data source's include it.
        let counts = (0..<sectionCount).map {
            (old: collectionView.numberOfItems(inSection: $0), new: dataSource.collectionView(collectionView, numberOfItemsInSection: $0))
        }
        let rows = counts[rowsSection]
        // An empty list needs the screen's empty-folder view, which only the whole reload sets.
        guard rows.old == first, rows.new >= first, rows.new > 0,
              counts.indices.allSatisfy({ $0 == rowsSection || $0 == sectionIndex || counts[$0].old == counts[$0].new }) else { return false }
        let skeletons = counts[sectionIndex]
        let offset = collectionView.contentOffset
        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates {
                collectionView.insertItems(at: (first..<rows.new).map { IndexPath(item: $0, section: rowsSection) })
                if skeletons.new < skeletons.old {
                    collectionView.deleteItems(at: (skeletons.new..<skeletons.old).map { IndexPath(item: $0, section: sectionIndex) })
                } else if skeletons.new > skeletons.old {
                    collectionView.insertItems(at: (skeletons.old..<skeletons.new).map { IndexPath(item: $0, section: sectionIndex) })
                }
            }
            // With only skeleton rows on screen, UIKit keeps them there and puts the new rows above the screen.
            guard collectionView.contentOffset != offset else { return }
            let bottom = collectionView.contentSize.height + collectionView.adjustedContentInset.bottom - collectionView.bounds.height
            collectionView.contentOffset = CGPoint(x: offset.x, y: min(offset.y, max(bottom, -collectionView.adjustedContentInset.top)))
        }
        return true
    }
}
