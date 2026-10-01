//
//  FileListDrag.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.09.2026.
//

import UIKit

/// Drag to move, as in the Files app: a lifted row follows the finger, a folder row it may go into turns grey,
/// and a drop moves it there. Hovering a folder opens it; a drop on the rest of the list moves into the open folder.
final class FileListDrag: NSObject, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    struct Handlers {
        /// The row's file when a drag may start from it, or take it in.
        let draggableFile: (IndexPath) -> FileModel?
        /// The folder a row stands for, when files may go into it.
        let folderRow: (IndexPath) -> FileModel?
        /// The folder on screen when files may be dropped into it, or nil when the list takes no drops.
        let openFolder: () -> FileModel?
        /// A point under the pinned sort row belongs to no file row.
        let isUnderPinnedHeader: (CGPoint) -> Bool
        let drop: (_ files: [FileModel], _ destination: FileModel) -> Void
        let dragDidEnd: () -> Void
        /// The folder under the finger changed, so the visible rows need `showLook(on:for:)` again.
        let lookDidChange: () -> Void
    }

    /// Where a drag began; the files it carries sit on its items.
    final class Context {
        let sourceFolderLinkId: Int
        /// The list the drag began in. Another workspace's list takes nothing from it.
        weak var origin: FileListDrag?
        init(sourceFolderLinkId: Int, origin: FileListDrag? = nil) {
            self.sourceFolderLinkId = sourceFolderLinkId
            self.origin = origin
        }
    }

    enum Target: Equatable {
        case folderRow(FileModel)
        case openFolder(FileModel)
        /// Nothing happens there: the files are already in that folder.
        case stay
        case refused
    }

    private let handlers: Handlers
    private weak var session: UIDragSession?
    private var navigating = false
    /// From the drop on, nothing waits for the drag: the moved rows leave the list at once.
    private var dropped = false
    private var heldReloads: [() -> Void] = []
    private var targetFolder: FileModel?
    private weak var list: UICollectionView?
    /// The list's own bottom inset, kept while a drag runs on a shallower one.
    private var restingBottomInset: CGFloat?

    /// iOS scrolls a drag that nears the edge of the bottom inset, and the lists rest on one that reaches mid-screen.
    static let dragBottomInset: CGFloat = 60

    init(handlers: Handlers) {
        self.handlers = handlers
        super.init()
    }

    var isDragging: Bool { session != nil }

    /// Set on the list's own rows, not left to the cells' drop state, which a reload during a drag can leave stale.
    func showLook(on cell: FileCollectionViewCell, for file: FileModel) {
        cell.showDropTarget(targetFolder.map { Self.isSameItem($0, file) } ?? false)
    }

    private func setTarget(_ folder: FileModel?) {
        switch (folder, targetFolder) {
        case (nil, nil): return
        case let (new?, old?) where Self.isSameItem(new, old): return
        default: break
        }
        targetFolder = folder
        handlers.lookDidChange()
    }

    // MARK: - Where files may go

    /// `folderRowDropIndexPath` is the folder row under the finger, when the list's own drop index agrees.
    func target(for files: [FileModel], from context: Context, folderRowAt folderRowDropIndexPath: IndexPath?) -> Target {
        guard let open = handlers.openFolder() else { return .refused }
        if let indexPath = folderRowDropIndexPath, let folder = handlers.folderRow(indexPath) {
            // A folder let go over its own row stays where it is.
            return files.contains { Self.isSameItem($0, folder) } ? .stay : .folderRow(folder)
        }
        if open.folderLinkId == context.sourceFolderLinkId { return .stay }
        return files.contains { $0.type.isFolder && $0.folderLinkId == open.folderLinkId } ? .refused : .openFolder(open)
    }

    static func proposal(for target: Target) -> UICollectionViewDropProposal {
        switch target {
        case .folderRow: return UICollectionViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
        case .openFolder: return UICollectionViewDropProposal(operation: .move, intent: .unspecified)
        case .stay: return UICollectionViewDropProposal(operation: .cancel)
        case .refused: return UICollectionViewDropProposal(operation: .forbidden)
        }
    }

    /// Hovering opens a folder the files may go into, never one of them.
    func shouldSpringLoad(_ indexPath: IndexPath) -> Bool {
        guard let session, session.localContext is Context, handlers.openFolder() != nil, let folder = handlers.folderRow(indexPath) else { return false }
        return !Self.files(in: session).contains { Self.isSameItem($0, folder) }
    }

    static func isSameItem(_ a: FileModel, _ b: FileModel) -> Bool {
        a.recordId == b.recordId && a.folderLinkId == b.folderLinkId
    }

    static func files(in session: UIDragSession) -> [FileModel] {
        session.items.compactMap { $0.localObject as? FileModel }
    }

    /// The back arrow goes up when a drag hovers it for a moment, while `canGoUp` allows it.
    static func springLoadedBackArrow(canGoUp: @escaping () -> Bool, goUp: @escaping () -> Void) -> UISpringLoadedInteraction {
        UISpringLoadedInteraction(interactionBehavior: Gate(allows: canGoUp), interactionEffect: nil) { _, _ in goUp() }
    }

    /// Keeps the back arrow from blinking at a drag it will not take up.
    private final class Gate: NSObject, UISpringLoadedInteractionBehavior {
        private let allows: () -> Bool
        init(allows: @escaping () -> Bool) { self.allows = allows }
        func shouldAllow(_ interaction: UISpringLoadedInteraction, with context: UISpringLoadedInteractionContext) -> Bool { allows() }
    }

    private static func item(for file: FileModel) -> UIDragItem {
        // Each item gets its own provider: several items sharing one can lose the drop.
        let item = UIDragItem(itemProvider: NSItemProvider())
        item.localObject = file
        return item
    }

    // MARK: - Holding the list still

    /// While a finger drags, list reloads wait and run when the drag ends. A folder the drag opened, and a page that
    /// only adds rows at the end, go ahead: neither moves a row under the finger.
    func holdsReload(addingPage: Bool = false, _ reload: @escaping () -> Void) -> Bool {
        guard isDragging, !navigating, !dropped, !addingPage else { return false }
        heldReloads.append(reload)
        return true
    }

    /// A folder the drag opens, by hovering, fills the list while the finger still drags.
    func navigationWillStart() {
        if isDragging { navigating = true }
    }

    func navigationDidEnd() {
        navigating = false
        if isDragging, !dropped { trimBottomInset() }
    }

    private func dragEnded() {
        session = nil
        // iOS ends the drag as the dropped files set off, and their folder stays grey while they fly in.
        if !dropped { targetFolder = nil }
        restoreBottomInset()
        runHeldReloads()
        handlers.lookDidChange()
        handlers.dragDidEnd()
    }

    private func runHeldReloads() {
        let reloads = heldReloads
        heldReloads = []
        reloads.forEach { $0() }
    }

    // MARK: - Scrolling under a drag

    /// As shallow as `dragBottomInset`, but deep enough to hold the list where it is.
    private func trimBottomInset() {
        guard let list, let resting = restingBottomInset else { return }
        let offset = list.contentOffset.y, systemInset = list.adjustedContentInset.bottom - list.contentInset.bottom
        // A list at its top stays there on any inset.
        let holdsOffset = offset > -list.adjustedContentInset.top ? offset + list.bounds.height - list.contentSize.height - systemInset : 0
        list.contentInset.bottom = min(resting, max(Self.dragBottomInset, holdsOffset.rounded(.up)))
    }

    private func restoreBottomInset() {
        guard let list, let resting = restingBottomInset else { return }
        restingBottomInset = nil
        list.contentInset.bottom = resting
    }

    // MARK: - UICollectionViewDragDelegate

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // Called on every long press, menu ones too, so it only answers.
        guard let file = handlers.draggableFile(indexPath), let open = handlers.openFolder() else { return [] }
        session.localContext = Context(sourceFolderLinkId: open.folderLinkId, origin: self)
        return [Self.item(for: file)]
    }

    /// A tap on another row with a second finger adds it, when it comes from the same folder.
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        guard let context = session.localContext as? Context, context.origin === self, handlers.openFolder()?.folderLinkId == context.sourceFolderLinkId,
              let file = handlers.draggableFile(indexPath), !Self.files(in: session).contains(where: { Self.isSameItem($0, file) })
        else { return [] }
        return [Self.item(for: file)]
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return nil }
        let parameters = UIDragPreviewParameters()
        parameters.visiblePath = FileContextMenu.liftedPath(for: cell, in: collectionView)
        return parameters
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        true
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        self.session = session
        navigating = false
        dropped = false
        restoreBottomInset()
        list = collectionView
        restingBottomInset = collectionView.contentInset.bottom
        trimBottomInset()
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        // Only the drag under way ends here: an earlier one can report its end after the next began.
        guard self.session == nil || self.session === session else { return }
        dragEnded()
    }

    // MARK: - UICollectionViewDropDelegate

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        (session.localDragSession?.localContext as? Context)?.origin === self
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let target = target(for: session, destinationIndexPath: destinationIndexPath, in: collectionView)
        if case .folderRow(let folder) = target { setTarget(folder) } else { setTarget(nil) }
        return Self.proposal(for: target)
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidExit session: UIDropSession) {
        setTarget(nil)
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
        setTarget(nil)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let target = target(for: coordinator.session, destinationIndexPath: coordinator.destinationIndexPath, in: collectionView)
        let destination: FileModel
        switch target {
        case .folderRow(let folder), .openFolder(let folder): destination = folder
        case .stay, .refused: return
        }
        // iOS reports the files in about a second after they land, so the move starts now.
        dropped = true
        restoreBottomInset()
        runHeldReloads()
        handlers.drop(coordinator.items.compactMap { $0.dragItem.localObject as? FileModel }, destination)

        var center = coordinator.session.location(in: collectionView)
        if case .folderRow = target, let icon = iconCenter(of: destination, in: collectionView) { center = icon }
        let shrink = UIDragPreviewTarget(container: collectionView, center: center, transform: CGAffineTransform(scaleX: 0.1, y: 0.1))
        let animators = coordinator.items.map { coordinator.drop($0.dragItem, to: shrink) }
        // The folder's grey fades as the files fly into it.
        guard let first = animators.first else { return setTarget(nil) }
        first.addAnimations { [weak self] in self?.setTarget(nil) }
        first.addCompletion { [weak self] _ in self?.setTarget(nil) }
    }

    /// The folder's icon once the moved rows have left, so the files fly to where it is now. A point, not the row:
    /// iOS keeps a drag's own row faded while files drop into it, and the folder can take that row's place.
    private func iconCenter(of folder: FileModel, in collectionView: UICollectionView) -> CGPoint? {
        collectionView.layoutIfNeeded()
        guard let indexPath = collectionView.indexPathsForVisibleItems.first(where: { handlers.folderRow($0).map { Self.isSameItem($0, folder) } ?? false }),
              let cell = collectionView.cellForItem(at: indexPath) else { return nil }
        let icon = Self.iconRect(in: cell)
        return collectionView.convert(CGPoint(x: icon.midX, y: icon.midY), from: cell)
    }

    func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        self.collectionView(collectionView, dragPreviewParametersForItemAt: indexPath)
    }

    /// The finger must be inside the folder row itself: the list's drop index can name the row next to it.
    private func target(for session: UIDropSession, destinationIndexPath: IndexPath?, in collectionView: UICollectionView) -> Target {
        guard let drag = session.localDragSession, let context = drag.localContext as? Context else { return .refused }
        let point = session.location(in: collectionView)
        var folderRowIndexPath: IndexPath?
        if !handlers.isUnderPinnedHeader(point), let underFinger = collectionView.indexPathForItem(at: point),
           destinationIndexPath == nil || destinationIndexPath == underFinger {
            folderRowIndexPath = underFinger
        }
        return target(for: Self.files(in: drag), from: context, folderRowAt: folderRowIndexPath)
    }

    /// Where a dropped file shrinks to: the folder's icon, on the row's leading side.
    private static func iconRect(in cell: UICollectionViewCell) -> CGRect {
        let icon = (cell as? FileCollectionViewCell)?.fileImageView
        return icon.map { cell.convert($0.bounds, from: $0) } ?? CGRect(x: 0, y: 0, width: cell.bounds.height, height: cell.bounds.height)
    }
}
