//
//  FileListDragTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 30.09.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class FileListDragTests: XCTestCase {
    // MARK: - Fakes: a list of rows, and the sessions and coordinator UIKit would hand over

    private final class Rows: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        var files: [FileModel]
        init(_ files: [FileModel]) { self.files = files }
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { files.count }
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            collectionView.dequeueReusableCell(withReuseIdentifier: "row", for: indexPath)
        }
        func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            CGSize(width: collectionView.bounds.width, height: 74)
        }
    }

    private final class DragSession: NSObject, UIDragSession {
        var localContext: Any?
        var items: [UIDragItem] = []
        var point: CGPoint = .zero
        func location(in view: UIView) -> CGPoint { point }
        var allowsMoveOperation: Bool { true }
        var isRestrictedToDraggingApplication: Bool { true }
        func hasItemsConforming(toTypeIdentifiers typeIdentifiers: [String]) -> Bool { false }
        func canLoadObjects(ofClass aClass: NSItemProviderReading.Type) -> Bool { false }
    }

    private final class DropSession: NSObject, UIDropSession {
        let drag: DragSession
        init(_ drag: DragSession) { self.drag = drag }
        var localDragSession: UIDragSession? { drag }
        var progressIndicatorStyle: UIDropSessionProgressIndicatorStyle = .none
        func loadObjects(ofClass aClass: NSItemProviderReading.Type, completion: @escaping ([NSItemProviderReading]) -> Void) -> Progress { Progress() }
        var items: [UIDragItem] { drag.items }
        func location(in view: UIView) -> CGPoint { drag.point }
        var allowsMoveOperation: Bool { true }
        var isRestrictedToDraggingApplication: Bool { true }
        func hasItemsConforming(toTypeIdentifiers typeIdentifiers: [String]) -> Bool { false }
        func canLoadObjects(ofClass aClass: NSItemProviderReading.Type) -> Bool { false }
        nonisolated var progress: Progress { Progress() }
    }

    private final class DropItem: NSObject, UICollectionViewDropItem {
        let dragItem: UIDragItem
        init(_ dragItem: UIDragItem) { self.dragItem = dragItem }
        var sourceIndexPath: IndexPath? { nil }
        var previewSize: CGSize { .zero }
    }

    private final class Animator: NSObject, UIDragAnimating {
        private var animations: [() -> Void] = []
        private var completions: [(UIViewAnimatingPosition) -> Void] = []
        func addAnimations(_ animations: @escaping () -> Void) { self.animations.append(animations) }
        func addCompletion(_ completion: @escaping (UIViewAnimatingPosition) -> Void) { completions.append(completion) }
        func finish() {
            animations.forEach { $0() }
            completions.forEach { $0(.end) }
        }
    }

    private final class Coordinator: NSObject, UICollectionViewDropCoordinator {
        let session: UIDropSession
        let items: [UICollectionViewDropItem]
        let destinationIndexPath: IndexPath?
        var proposal: UICollectionViewDropProposal { UICollectionViewDropProposal(operation: .move) }
        /// Where each file shrinks to, in the list.
        private(set) var droppedAt: [CGPoint] = []
        let animator = Animator()
        init(session: DropSession, destinationIndexPath: IndexPath?) {
            self.session = session
            self.items = session.drag.items.map(DropItem.init)
            self.destinationIndexPath = destinationIndexPath
        }
        func drop(_ dragItem: UIDragItem, to placeholder: UICollectionViewDropPlaceholder) -> UICollectionViewDropPlaceholderContext {
            fatalError("a drag to move never inserts placeholders")
        }
        func drop(_ dragItem: UIDragItem, toItemAt indexPath: IndexPath) -> UIDragAnimating { animator }
        func drop(_ dragItem: UIDragItem, intoItemAt indexPath: IndexPath, rect: CGRect) -> UIDragAnimating { animator }
        func drop(_ dragItem: UIDragItem, to target: UIDragPreviewTarget) -> UIDragAnimating {
            droppedAt.append(target.center)
            return animator
        }
    }

    // MARK: - A folder of three rows: a photo, a folder, a second photo

    private let current = FileModel(name: "Photography", recordId: 0, folderLinkId: 10, archiveNbr: "0001", type: "type.folder.private", permissions: [.read])
    private let photo = FileModel(name: "August_Hike_003.jpg", recordId: 1, folderLinkId: 11, archiveNbr: "0001", type: "type.record.image", permissions: [.read, .move])
    private let folder = FileModel(name: "Beach trip 2023", recordId: 0, folderLinkId: 12, archiveNbr: "0001", type: "type.folder.private", permissions: [.read, .move])
    private let secondPhoto = FileModel(name: "Beach at sunset.jpg", recordId: 3, folderLinkId: 13, archiveNbr: "0001", type: "type.record.image", permissions: [.read, .move])

    private lazy var rows: [FileModel] = [photo, folder, secondPhoto]
    private var open: FileModel?
    private var dropped: [([FileModel], FileModel)] = []
    /// What the screen does with its rows as a drop starts the move.
    private var onDrop: () -> Void = {}
    private var dragEnds = 0
    private var lookChanges = 0

    private func makeDrag() -> FileListDrag {
        open = current
        return FileListDrag(handlers: .init(
            draggableFile: { [unowned self] indexPath in rows[indexPath.item] },
            folderRow: { [unowned self] indexPath in rows[indexPath.item].type.isFolder ? rows[indexPath.item] : nil },
            openFolder: { [unowned self] in open },
            isUnderPinnedHeader: { $0.y < 20 },
            drop: { [unowned self] files, destination in
                dropped.append((files, destination))
                onDrop()
            },
            dragDidEnd: { [unowned self] in dragEnds += 1 },
            lookDidChange: { [unowned self] in lookChanges += 1 }
        ))
    }

    private func makeList(_ source: Rows) -> UICollectionView {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        let list = UICollectionView(frame: window.bounds, collectionViewLayout: layout)
        list.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "row")
        list.dataSource = source
        list.delegate = source
        window.addSubview(list)
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
        list.layoutIfNeeded()
        return list
    }

    /// A drag already under way from the photo's row, with the photo on it.
    private func startDrag(_ drag: FileListDrag, on list: UICollectionView) -> DragSession {
        let session = DragSession()
        session.items = drag.collectionView(list, itemsForBeginning: session, at: IndexPath(item: 0, section: 0))
        drag.collectionView(list, dragSessionWillBegin: session)
        return session
    }

    // MARK: - Where a file may go

    func testAFolderRow_TakesTheFiles_AndAFolderOverItsOwnRowStays() {
        let drag = makeDrag(), context = FileListDrag.Context(sourceFolderLinkId: current.folderLinkId)
        let row = IndexPath(item: 1, section: 0)

        XCTAssertEqual(drag.target(for: [photo], from: context, folderRowAt: row), .folderRow(folder))
        XCTAssertEqual(drag.target(for: [photo, folder], from: context, folderRowAt: row), .stay, "never into itself, and no stop sign either")
    }

    func testTheRestOfTheList_IsTheOpenFolder_WhereFilesFromItStay() {
        let drag = makeDrag()
        let fromHere = FileListDrag.Context(sourceFolderLinkId: current.folderLinkId)
        let fromElsewhere = FileListDrag.Context(sourceFolderLinkId: 99)

        XCTAssertEqual(drag.target(for: [photo], from: fromHere, folderRowAt: nil), .stay)
        XCTAssertEqual(drag.target(for: [photo], from: fromElsewhere, folderRowAt: nil), .openFolder(current))
    }

    func testAListWithNoOpenFolder_TakesNoDrops() {
        let drag = makeDrag()
        open = nil

        XCTAssertEqual(drag.target(for: [photo], from: .init(sourceFolderLinkId: 99), folderRowAt: IndexPath(item: 1, section: 0)), .refused)
    }

    func testEachTarget_GetsTheFilesAppLook() {
        let intoFolder = FileListDrag.proposal(for: .folderRow(folder))
        XCTAssertEqual(intoFolder.operation, .move)
        XCTAssertEqual(intoFolder.intent, .insertIntoDestinationIndexPath, "the folder row turns grey")
        XCTAssertEqual(FileListDrag.proposal(for: .openFolder(current)).intent, .unspecified)
        XCTAssertEqual(FileListDrag.proposal(for: .stay).operation, .cancel)
        XCTAssertEqual(FileListDrag.proposal(for: .refused).operation, .forbidden)
    }

    // MARK: - Picking files up

    func testALift_CarriesTheFile_AndWhereItCameFrom() throws {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let session = DragSession()

        let items = drag.collectionView(list, itemsForBeginning: session, at: IndexPath(item: 0, section: 0))

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.localObject as? FileModel, photo)
        XCTAssertEqual(try XCTUnwrap(session.localContext as? FileListDrag.Context).sourceFolderLinkId, current.folderLinkId)
    }

    func testASecondFingersTap_AddsAnotherRowOnce_OnlyFromTheSameFolder() {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let session = startDrag(drag, on: list)

        let added = drag.collectionView(list, itemsForAddingTo: session, at: IndexPath(item: 2, section: 0), point: .zero)
        XCTAssertEqual(added.map { $0.localObject as? FileModel }, [secondPhoto])
        session.items += added
        XCTAssertEqual(drag.collectionView(list, itemsForAddingTo: session, at: IndexPath(item: 0, section: 0), point: .zero).count, 0, "the photo is already on the drag")

        open = FileModel(name: "Beach trip 2023", recordId: 0, folderLinkId: 12, archiveNbr: "0001", type: "type.folder.private", permissions: [.read])
        XCTAssertEqual(drag.collectionView(list, itemsForAddingTo: session, at: IndexPath(item: 2, section: 0), point: .zero).count, 0, "a hovered-open folder adds nothing")
    }

    func testEachFileOnTheDrag_HasItsOwnProvider() {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let session = startDrag(drag, on: list)
        session.items += drag.collectionView(list, itemsForAddingTo: session, at: IndexPath(item: 2, section: 0), point: .zero)

        XCTAssertFalse(session.items[0].itemProvider === session.items[1].itemProvider)
    }

    // MARK: - The look under a drag

    func testTheFolderUnderTheFinger_TurnsGrey_UntilTheFingerLeavesOrTheDragEnds() throws {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let cell = try XCTUnwrap(UINib(nibName: "FileCollectionViewCell", bundle: nil).instantiate(withOwner: nil).first as? FileCollectionViewCell)
        let session = startDrag(drag, on: list)
        let panel = try XCTUnwrap(cell.overlayView.superview)
        let resting = panel.backgroundColor
        drag.showLook(on: cell, for: folder)
        XCTAssertEqual(panel.backgroundColor, resting)

        session.point = CGPoint(x: 100, y: 74 + 37)
        _ = drag.collectionView(list, dropSessionDidUpdate: DropSession(session), withDestinationIndexPath: IndexPath(item: 1, section: 0))
        XCTAssertEqual(lookChanges, 1)
        drag.showLook(on: cell, for: folder)
        XCTAssertEqual(panel.backgroundColor, .galleryGray)
        drag.showLook(on: cell, for: photo)
        XCTAssertEqual(panel.backgroundColor, resting, "only the folder row")

        session.point = CGPoint(x: 100, y: 37)
        _ = drag.collectionView(list, dropSessionDidUpdate: DropSession(session), withDestinationIndexPath: IndexPath(item: 0, section: 0))
        drag.showLook(on: cell, for: folder)
        XCTAssertEqual(panel.backgroundColor, resting, "the finger moved on")

        session.point = CGPoint(x: 100, y: 74 + 37)
        _ = drag.collectionView(list, dropSessionDidUpdate: DropSession(session), withDestinationIndexPath: IndexPath(item: 1, section: 0))
        drag.collectionView(list, dragSessionDidEnd: session)
        drag.showLook(on: cell, for: folder)
        XCTAssertEqual(panel.backgroundColor, resting, "no row stays grey after the drag")
    }

    func testAReusedCell_ForgetsTheGrey() throws {
        let cell = try XCTUnwrap(UINib(nibName: "FileCollectionViewCell", bundle: nil).instantiate(withOwner: nil).first as? FileCollectionViewCell)
        let panel = try XCTUnwrap(cell.overlayView.superview)
        let resting = panel.backgroundColor
        cell.showDropTarget(true)
        XCTAssertEqual(panel.backgroundColor, .galleryGray, "the white panel over the cell's own background turns grey")

        cell.prepareForReuse()

        XCTAssertEqual(panel.backgroundColor, resting)
    }

    func testOnlyARowHoldingADraggedFile_LooksLifted() throws {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let cell = try XCTUnwrap(UINib(nibName: "FileCollectionViewCell", bundle: nil).instantiate(withOwner: nil).first as? FileCollectionViewCell)
        let session = startDrag(drag, on: list)

        // iOS fades the row at the photo's place, also once a hover has put another file there.
        drag.showLook(on: cell, for: secondPhoto)
        cell.alpha = 0.5
        cell.dragStateDidChange(.dragging)
        XCTAssertEqual(cell.alpha, 1, "another file keeps its full colour")

        drag.showLook(on: cell, for: photo)
        cell.alpha = 0.5
        cell.dragStateDidChange(.dragging)
        XCTAssertEqual(cell.alpha, 0.5, "the photo's own row stays faded, as in the Files app")

        session.point = CGPoint(x: 100, y: 74 + 37)
        drag.collectionView(list, performDropWith: Coordinator(session: DropSession(session), destinationIndexPath: IndexPath(item: 1, section: 0)))
        drag.showLook(on: cell, for: secondPhoto)
        cell.alpha = 0.5
        cell.dragStateDidChange(.dragging)
        XCTAssertEqual(cell.alpha, 0.5, "a drop keeps the look it had")

        drag.collectionView(list, dragSessionDidEnd: session)
        drag.showLook(on: cell, for: secondPhoto)
        cell.alpha = 0.5
        cell.dragStateDidChange(.dragging)
        XCTAssertEqual(cell.alpha, 0.5, "with no drag of its own, the list leaves the look to iOS")
    }

    // MARK: - A cancelled drag

    func testACancelledDrag_FliesBackToItsRow_WhileTheRowHoldsTheFile() throws {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        _ = startDrag(drag, on: list)

        let parameters = try XCTUnwrap(drag.collectionView(list, dragPreviewParametersForItemAt: IndexPath(item: 0, section: 0)))

        let cell = try XCTUnwrap(list.cellForItem(at: IndexPath(item: 0, section: 0)))
        XCTAssertEqual(parameters.visiblePath?.bounds, FileContextMenu.liftedPath(for: cell, in: list).bounds, "the photo's own row")
        XCTAssertNotEqual(parameters.backgroundColor, .clear)
    }

    func testACancelledDrag_FadesWhereTheFingerLetGo_WhileAHoverShowsAnotherFileInItsPlace() throws {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let session = DragSession()
        session.point = CGPoint(x: 150, y: 37)
        session.items = drag.collectionView(list, itemsForBeginning: session, at: IndexPath(item: 0, section: 0))
        drag.collectionView(list, dragSessionWillBegin: session)

        // Hovering opens the folder, whose first row is another photo, and the finger lets go above the list.
        let dunes = FileModel(name: "Dunes.jpg", recordId: 4, folderLinkId: 14, archiveNbr: "0001", type: "type.record.image", permissions: [.read, .move])
        drag.navigationWillStart()
        open = folder
        rows = [dunes]
        source.files = rows
        list.reloadData()
        list.layoutIfNeeded()
        drag.navigationDidEnd()
        session.point = CGPoint(x: 200, y: -60)

        let parameters = try XCTUnwrap(drag.collectionView(list, dragPreviewParametersForItemAt: IndexPath(item: 0, section: 0)))
        let cell = try XCTUnwrap(list.cellForItem(at: IndexPath(item: 0, section: 0)))
        let lifted = FileContextMenu.liftedPath(for: cell, in: list).bounds
        XCTAssertEqual(parameters.visiblePath?.bounds, lifted.offsetBy(dx: 50, dy: -97), "the card stays where the finger let it go")
        XCTAssertEqual(parameters.backgroundColor, .clear, "and fades, with nothing of Dunes in it")
        XCTAssertEqual(parameters.shadowPath?.isEmpty, true)
        XCTAssertEqual(drag.collectionView(list, dropPreviewParametersForItemAt: IndexPath(item: 0, section: 0))?.visiblePath?.bounds, lifted, "a drop keeps its look")

        // Back in the photo's own folder, the card flies home again.
        open = current
        rows = [photo, folder, secondPhoto]
        source.files = rows
        list.reloadData()
        list.layoutIfNeeded()
        let home = try XCTUnwrap(drag.collectionView(list, dragPreviewParametersForItemAt: IndexPath(item: 0, section: 0)))
        XCTAssertEqual(home.visiblePath?.bounds, lifted)
    }

    func testARowAddedByASecondFinger_LiftsWithTheUsualOutline() throws {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let session = startDrag(drag, on: list)

        // The added file need not be on the session's items yet when iOS asks for its lift.
        _ = drag.collectionView(list, itemsForAddingTo: session, at: IndexPath(item: 2, section: 0), point: .zero)
        let parameters = try XCTUnwrap(drag.collectionView(list, dragPreviewParametersForItemAt: IndexPath(item: 2, section: 0)))

        let cell = try XCTUnwrap(list.cellForItem(at: IndexPath(item: 2, section: 0)))
        XCTAssertEqual(parameters.visiblePath?.bounds, FileContextMenu.liftedPath(for: cell, in: list).bounds)
    }

    // MARK: - Hovering

    func testHovering_OpensAFolderTheFilesMayGoInto_NeverOneOfThem() {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        XCTAssertFalse(drag.shouldSpringLoad(IndexPath(item: 1, section: 0)), "no drag, no hover")

        let session = startDrag(drag, on: list)
        XCTAssertTrue(drag.shouldSpringLoad(IndexPath(item: 1, section: 0)))
        XCTAssertFalse(drag.shouldSpringLoad(IndexPath(item: 2, section: 0)), "a file row never opens")

        session.items.append({ let item = UIDragItem(itemProvider: NSItemProvider()); item.localObject = folder; return item }())
        XCTAssertFalse(drag.shouldSpringLoad(IndexPath(item: 1, section: 0)), "the dragged folder never opens under itself")
        withExtendedLifetime(session) {}
    }

    // MARK: - Holding the list still

    func testReloads_WaitForTheDrag_ExceptThoseOfAFolderTheDragOpens() {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        var reloads = 0
        XCTAssertFalse(drag.holdsReload { reloads += 1 }, "no drag, no wait")

        let session = startDrag(drag, on: list)
        XCTAssertTrue(drag.holdsReload { reloads += 1 })
        drag.navigationWillStart()
        XCTAssertFalse(drag.holdsReload { reloads += 1 }, "the opened folder fills the list under the finger")
        drag.navigationDidEnd()
        XCTAssertTrue(drag.holdsReload { reloads += 1 })
        XCTAssertEqual(reloads, 0)

        drag.collectionView(list, dragSessionDidEnd: session)
        XCTAssertEqual(reloads, 2, "each held reload runs once the finger lifts")
        XCTAssertEqual(dragEnds, 1)
        XCTAssertFalse(drag.isDragging)
    }

    func testAPageThatOnlyAddsRows_LandsDuringTheDrag() {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let session = startDrag(drag, on: list)
        var reloads = 0

        XCTAssertFalse(drag.holdsReload(addingPage: true) { reloads += 1 }, "the next page shows while the finger drags")
        XCTAssertTrue(drag.holdsReload { reloads += 1 }, "other reloads still wait")
        withExtendedLifetime(session) {}
    }

    // MARK: - Scrolling under a drag

    func testADrag_RunsOnAShallowBottomInset_AndTheListGetsItsOwnBack() {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        list.contentInset.bottom = 362

        let session = startDrag(drag, on: list)
        XCTAssertEqual(list.contentInset.bottom, FileListDrag.dragBottomInset, "iOS scrolls only near the bottom now")

        drag.collectionView(list, dragSessionDidEnd: session)
        XCTAssertEqual(list.contentInset.bottom, 362)
    }

    func testTheShallowInset_HoldsTheListWhereItIs() {
        rows = Array(repeating: photo, count: 20)
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        list.contentInset.bottom = 362
        let deepest = list.contentSize.height + 362 - list.bounds.height
        list.contentOffset.y = deepest

        let session = startDrag(drag, on: list)
        XCTAssertEqual(list.contentInset.bottom, 362, "scrolled all the way down, the list needs all of its inset")
        XCTAssertEqual(list.contentOffset.y, deepest)

        list.contentOffset.y = deepest - 200
        drag.navigationDidEnd()
        XCTAssertEqual(list.contentInset.bottom, 162, "a folder the drag opens gets the inset that holds it too")

        drag.collectionView(list, dragSessionDidEnd: session)
        XCTAssertEqual(list.contentInset.bottom, 362)
    }

    func testTheInsetComesBack_AtTheDrop() {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        list.contentInset.bottom = 362
        let session = startDrag(drag, on: list)
        session.point = CGPoint(x: 100, y: 74 + 37)
        let coordinator = Coordinator(session: DropSession(session), destinationIndexPath: IndexPath(item: 1, section: 0))

        drag.collectionView(list, performDropWith: coordinator)

        XCTAssertEqual(list.contentInset.bottom, 362, "the moved rows leave a list on its own inset")
        XCTAssertTrue(drag.isDragging)
    }

    func testAnEarlierDragEndingLate_LeavesTheNextOneAlone() {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        list.contentInset.bottom = 362
        let first = startDrag(drag, on: list)
        let second = startDrag(drag, on: list)

        drag.collectionView(list, dragSessionDidEnd: first)
        XCTAssertTrue(drag.isDragging)
        XCTAssertEqual(list.contentInset.bottom, FileListDrag.dragBottomInset)

        drag.collectionView(list, dragSessionDidEnd: second)
        XCTAssertFalse(drag.isDragging)
        XCTAssertEqual(list.contentInset.bottom, 362)
    }

    // MARK: - Dropping

    func testADropOnAFolderRow_MovesTheFile_AndShrinksItIntoTheFolder() {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let session = startDrag(drag, on: list)
        session.point = CGPoint(x: 100, y: 74 + 37)
        let folderRow = IndexPath(item: 1, section: 0)
        let coordinator = Coordinator(session: DropSession(session), destinationIndexPath: folderRow)

        drag.collectionView(list, performDropWith: coordinator)

        XCTAssertEqual(dropped.count, 1, "the move starts as the file sets off")
        XCTAssertEqual(dropped.first?.0, [photo])
        XCTAssertEqual(dropped.first?.1, folder)
        XCTAssertEqual(coordinator.droppedAt, [CGPoint(x: 37, y: 74 + 37)], "into the folder row's icon")
    }

    func testTheFileFlies_ToWhereTheFolderIsOnceTheMovedRowLeaves() {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let session = startDrag(drag, on: list)
        session.point = CGPoint(x: 100, y: 74 + 37)
        let coordinator = Coordinator(session: DropSession(session), destinationIndexPath: IndexPath(item: 1, section: 0))
        onDrop = { [unowned self] in
            rows.removeFirst()
            source.files.removeFirst()
            list.reloadData()
        }

        drag.collectionView(list, performDropWith: coordinator)

        XCTAssertEqual(coordinator.droppedAt, [CGPoint(x: 37, y: 37)], "the photo's row has left, and the folder moved up")
    }

    func testFromTheDrop_TheListNoLongerWaits() {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let session = startDrag(drag, on: list)
        var reloads = 0
        XCTAssertTrue(drag.holdsReload { reloads += 1 })
        session.point = CGPoint(x: 100, y: 74 + 37)
        let coordinator = Coordinator(session: DropSession(session), destinationIndexPath: IndexPath(item: 1, section: 0))

        drag.collectionView(list, performDropWith: coordinator)

        XCTAssertEqual(reloads, 1, "what waited runs before the moved rows leave")
        XCTAssertFalse(drag.holdsReload { reloads += 1 })
        XCTAssertTrue(drag.isDragging)
    }

    func testADroppedFolder_StaysGreyUntilTheFilesFlyIn_ThoughIOSEndsTheDragFirst() throws {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let cell = try XCTUnwrap(UINib(nibName: "FileCollectionViewCell", bundle: nil).instantiate(withOwner: nil).first as? FileCollectionViewCell)
        let panel = try XCTUnwrap(cell.overlayView.superview)
        let resting = panel.backgroundColor
        let session = startDrag(drag, on: list)
        session.point = CGPoint(x: 100, y: 74 + 37)
        let folderRow = IndexPath(item: 1, section: 0)
        _ = drag.collectionView(list, dropSessionDidUpdate: DropSession(session), withDestinationIndexPath: folderRow)
        let coordinator = Coordinator(session: DropSession(session), destinationIndexPath: folderRow)

        drag.collectionView(list, performDropWith: coordinator)
        drag.collectionView(list, dragSessionDidEnd: session)
        drag.showLook(on: cell, for: folder)
        XCTAssertEqual(panel.backgroundColor, .galleryGray)

        coordinator.animator.finish()
        drag.showLook(on: cell, for: folder)
        XCTAssertEqual(panel.backgroundColor, resting)
    }

    func testADropOnTheRowNextToTheFolder_IsNotADropIntoIt() {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let session = startDrag(drag, on: list)
        session.point = CGPoint(x: 100, y: 74 + 37)
        let proposal = drag.collectionView(list, dropSessionDidUpdate: DropSession(session), withDestinationIndexPath: IndexPath(item: 2, section: 0))

        XCTAssertEqual(proposal.operation, .cancel, "the list's drop index names the next row: the finger is not inside the folder")
    }

    func testADropUnderThePinnedSortRow_IsNoFolderRow() {
        rows = [folder, photo]
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let session = DragSession()
        session.items = drag.collectionView(list, itemsForBeginning: session, at: IndexPath(item: 1, section: 0))
        drag.collectionView(list, dragSessionWillBegin: session)
        session.point = CGPoint(x: 100, y: 10)

        let proposal = drag.collectionView(list, dropSessionDidUpdate: DropSession(session), withDestinationIndexPath: IndexPath(item: 0, section: 0))

        XCTAssertEqual(proposal.operation, .cancel)
    }

    func testADropInAFolderTheDragOpened_MovesIntoIt() {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let session = startDrag(drag, on: list)
        let beach = FileModel(name: "Beach trip 2023", recordId: 0, folderLinkId: 12, archiveNbr: "0001", type: "type.folder.private", permissions: [.read])
        open = beach
        session.point = CGPoint(x: 100, y: 700)
        let coordinator = Coordinator(session: DropSession(session), destinationIndexPath: nil)

        drag.collectionView(list, performDropWith: coordinator)
        coordinator.animator.finish()

        XCTAssertEqual(coordinator.droppedAt, [CGPoint(x: 100, y: 700)], "where the finger let go")
        XCTAssertEqual(dropped.first?.1, beach)
    }

    func testOnlyThisListsOwnDrags_AreTaken() {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let foreign = DragSession()

        XCTAssertFalse(drag.collectionView(list, canHandle: DropSession(foreign)), "a drag with no context came from somewhere else")
        XCTAssertTrue(drag.collectionView(list, canHandle: DropSession(startDrag(drag, on: list))))
    }

    func testAnotherWorkspacesList_TakesNothingFromTheDrag() {
        let drag = makeDrag(), source = Rows(rows), list = makeList(source)
        let session = startDrag(drag, on: list)
        let otherWorkspace = makeDrag(), otherList = makeList(Rows(rows))

        XCTAssertFalse(otherWorkspace.collectionView(otherList, canHandle: DropSession(session)), "no drop in another workspace")
        XCTAssertTrue(otherWorkspace.collectionView(otherList, itemsForAddingTo: session, at: IndexPath(item: 2, section: 0), point: .zero).isEmpty,
                      "and no rows added from it")
    }
}
