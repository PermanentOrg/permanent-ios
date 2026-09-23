//
//  FileListPagingSection.swift
//  Permanent
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

    private static let skeletonFadeIn: CFTimeInterval = 0.2
    private static let skeletonFadeOut: CFTimeInterval = 0.3
    /// Long enough for the placeholders to read as a step rather than a flicker when a page comes back at once.
    private static let skeletonMinimumTime: CFTimeInterval = 0.4

    private static let firstPageListRows = 8
    private static let firstPageGridTiles = 6
    private static let nextPageListRows = 3
    private static let nextPageGridTiles = 2

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
            self.onChange()
            if let firstNewChild = notification.userInfo?[FilesViewModel.firstNewChildKey] as? Int {
                self.fadeInRows(from: firstNewChild)
            }
            // After the redraw, so focus lands on the error and its retry button instead of a row that went silent.
            if viewModel.childrenPagingState == .failed, !viewModel.isLoadingFirstPage {
                self.moveAccessibilityFocus(to: self.visibleFooter)
            }
        })
        observers.append(center.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.collectionView?.collectionViewLayout.invalidateLayout()
        })
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
        case .loadingMore, .failed: return isGrid ? Self.nextPageGridTiles : Self.nextPageListRows
        }
    }

    func cell(at indexPath: IndexPath, isGrid: Bool) -> UICollectionViewCell {
        guard let collectionView,
              let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileSkeletonCollectionViewCell.identifier, for: indexPath) as? FileSkeletonCollectionViewCell else {
            return UICollectionViewCell()
        }
        // One placeholder speaks for the rest, so VoiceOver can tell the list goes on.
        let label = indexPath.item == 0 ? accessibilityLabelForSkeleton : nil
        cell.configure(isGrid: isGrid, accessibilityLabel: label)
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

    /// Skeleton rows coming into view are what ask for the next page. Driven by display rather than
    /// scroll offset, since the public archive tab rewrites `contentOffset` for its parent page.
    func willDisplayItem(at indexPath: IndexPath) {
        guard indexPath.section == sectionIndex, let viewModel = viewModel(), !viewModel.isLoadingFirstPage,
              viewModel.childrenPagingState == .loadingMore else { return }
        viewModel.loadNextChildrenPage { _ in }
    }
}
