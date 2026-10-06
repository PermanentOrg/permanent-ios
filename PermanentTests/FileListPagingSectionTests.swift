//
//  FileListPagingSectionTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 23.09.2026.
//

import XCTest
@testable import Permanent

final class FileListPagingSectionTests: XCTestCase {
    private var navParams: NavigateMinParams { ("0001-test", 11, nil) }

    private func makeFolder() -> FileModel {
        let json = """
        { "items": [ { "folderId": "10", "displayName": "Folder 10", "type": "private", "status": "ok",
          "folderLinkId": "11", "archiveNumber": "0001-test", "sort": "date-descending" } ] }
        """
        let response = try! FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: Data(json.utf8))
        return FileModel(model: response.items![0], permissions: [.read], accessRole: .viewer)
    }

    /// Records with folderLinkIds `linkIds`, plus one folder.
    private func page(_ linkIds: [Int], nextCursor: String?) -> Result<FolderChildrenV2Response, FilesViewModel.ChildrenPageFailure> {
        var items = linkIds.map { id in
            """
            { "recordId": "\(1000 + id)", "displayName": "photo-\(id).jpg", "archiveNumber": "0001-\(id)",
              "type": "type.record.image", "status": "ok", "folderLinkId": "\(id)" }
            """
        }
        items.append("""
        { "folderId": "500", "displayName": "Trips", "archiveNumber": "0001-500", "type": "private", "status": "ok", "folderLinkId": "500" }
        """)
        let cursorField = nextCursor.map { "\"\($0)\"" } ?? "null"
        let json = "{ \"items\": [\(items.joined(separator: ","))], \"pagination\": { \"nextCursor\": \(cursorField) } }"
        return .success(try! FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: Data(json.utf8)))
    }

    /// A view model inside a folder, answered from `responses` in order.
    /// One full page: the page size less one file, and the folder `page` adds, so another page is due.
    private var fullPage: Result<FolderChildrenV2Response, FilesViewModel.ChildrenPageFailure> {
        let files = FilesViewModel.childrenPageSize - 1
        return page(Array(1...files), nextCursor: "\(files)")
    }

    /// A full later page from record `start`: one record short of the page, and the folder `page` adds.
    private func fullNextPage(from start: Int) -> Result<FolderChildrenV2Response, FilesViewModel.ChildrenPageFailure> {
        let end = start + FilesViewModel.nextChildrenPageSize - 2
        return page(Array(start...end), nextCursor: "\(end)")
    }

    private func makeViewModel(responses: [Result<FolderChildrenV2Response, FilesViewModel.ChildrenPageFailure>]) -> MyFilesViewModel {
        let viewModel = MyFilesViewModel()
        var remaining = responses
        viewModel.childrenPageV2Request = { _, _, _, completion in completion(remaining.removeFirst()) }
        viewModel.v2NavigationTarget = makeFolder()
        let listed = expectation(description: "folder listed")
        viewModel.navigateMin(params: navParams, backNavigation: false) { _ in listed.fulfill() }
        wait(for: [listed], timeout: 5)
        return viewModel
    }

    /// Sections as the folder screens have them: the view model's own, then the paging section.
    private final class ListSource: NSObject, UICollectionViewDataSource {
        let viewModel: FilesViewModel
        var section: FileListPagingSection?
        init(_ viewModel: FilesViewModel) { self.viewModel = viewModel }

        func numberOfSections(in collectionView: UICollectionView) -> Int { viewModel.numberOfSections + 1 }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection index: Int) -> Int {
            guard let section, index == section.sectionIndex else { return viewModel.numberOfRowsInSection(index) }
            return section.numberOfItems(isGrid: false)
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            if let section, indexPath.section == section.sectionIndex { return section.cell(at: indexPath, isGrid: false) }
            return collectionView.dequeueReusableCell(withReuseIdentifier: "row", for: indexPath)
        }
    }

    /// A list of `height` points, with the file list's spacing and rows of `itemSize`.
    private func makeSection(for viewModel: FilesViewModel, height: CGFloat = 844, itemSize: CGSize = CGSize(width: 390, height: 74),
                             onChange: @escaping () -> Void = {}) -> FileListPagingSection {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing = 0
        layout.itemSize = itemSize
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 390, height: height), collectionViewLayout: layout)
        addTeardownBlock { _ = collectionView }
        return FileListPagingSection(collectionView: collectionView, viewModel: { viewModel }, onChange: onChange)
    }

    func testTheSectionComesAfterTheViewModelsOwn() {
        let viewModel = MyFilesViewModel()
        XCTAssertEqual(makeSection(for: viewModel).sectionIndex, viewModel.numberOfSections)
    }

    func testTheFirstPage_ShowsAScreenOfSkeletonsAndNoFooter() {
        let viewModel = makeViewModel(responses: [fullPage])
        let section = makeSection(for: viewModel)

        viewModel.isLoadingFirstPage = true

        XCTAssertEqual(section.numberOfItems(isGrid: false), 8)
        XCTAssertEqual(section.numberOfItems(isGrid: true), 6)
        XCTAssertEqual(section.footerContent, .hidden)
    }

    func testMorePagesDue_FillTheListWithSkeletonsUpToAPage_AndNoFooter() {
        let viewModel = makeViewModel(responses: [fullPage])
        let section = makeSection(for: viewModel)
        let grid = makeSection(for: viewModel, itemSize: CGSize(width: 189, height: 225))

        XCTAssertEqual(viewModel.childrenPagingState, .loadingMore)
        XCTAssertEqual(section.numberOfItems(isGrid: false), 12, "844 pt of 74 pt rows, so a full page lands in their place")
        XCTAssertEqual(grid.numberOfItems(isGrid: true), 8, "two tiles a line, four lines")
        XCTAssertEqual(makeSection(for: viewModel, height: 5000).numberOfItems(isGrid: false), FilesViewModel.nextChildrenPageSize, "never more than a page")
        XCTAssertEqual(makeSection(for: viewModel, height: 0).numberOfItems(isGrid: false), 3, "a list with no size yet")
        XCTAssertEqual(section.footerContent, .hidden)
    }

    func testAFailedPage_KeepsTheSkeletonRowsAndShowsTheRetryFooter() {
        let viewModel = makeViewModel(responses: [fullPage, .failure(.init(message: "offline"))])
        let section = makeSection(for: viewModel)
        let loaded = expectation(description: "page")
        viewModel.loadNextChildrenPage { _ in loaded.fulfill() }
        wait(for: [loaded], timeout: 5)

        XCTAssertEqual(section.numberOfItems(isGrid: false), 3, "a few, so the retry footer stays close to the rows")
        XCTAssertEqual(section.footerContent, .failed)
    }

    func testACompleteFolder_ShowsTheCountsAndNoSkeletons() {
        let viewModel = makeViewModel(responses: [page([1, 2, 3], nextCursor: "3")])
        let section = makeSection(for: viewModel)

        XCTAssertEqual(section.numberOfItems(isGrid: false), 0)
        XCTAssertEqual(section.footerContent, .counts(folders: 1, files: 3))
    }

    func testCounts_AreHiddenOutsideAFolderAndForAnEmptyOne() {
        let viewModel = makeViewModel(responses: [page([1, 2, 3], nextCursor: "3")])
        let section = makeSection(for: viewModel)

        // Rows still loaded, so only the folder check can hide the counts.
        let folderStack = viewModel.navigationStack
        viewModel.navigationStack.removeAll()
        XCTAssertEqual(section.footerContent, .hidden, "the share list and search results are not a folder")

        viewModel.navigationStack = folderStack
        viewModel.viewModels.removeAll()
        XCTAssertEqual(section.footerContent, .hidden, "an empty folder shows its empty view instead")
    }

    func testRowsInTheLastTwoScreens_LoadTheNextPageOnlyWhileOneIsDue() {
        var requests = 0
        let viewModel = makeViewModel(responses: [fullPage, .failure(.init(message: "offline"))])
        let answer = viewModel.childrenPageV2Request
        viewModel.childrenPageV2Request = { folderId, pageSize, cursor, completion in
            requests += 1
            answer?(folderId, pageSize, cursor, completion)
        }
        let changed = expectation(description: "screen told")
        let section = makeSection(for: viewModel, height: 370, onChange: { changed.fulfill() })
        let rows = section.sectionIndex - 1

        section.willDisplayItem(at: IndexPath(item: 9, section: rows))
        XCTAssertEqual(requests, 0, "20 rows and 5 a screen, so the first 10 rows never ask")

        section.willDisplayItem(at: IndexPath(item: 10, section: rows))
        wait(for: [changed], timeout: 5)
        XCTAssertEqual(requests, 1)

        section.willDisplayItem(at: IndexPath(item: 0, section: section.sectionIndex))
        XCTAssertEqual(requests, 1, "a failed page waits for the retry button")
    }

    /// A shown 390 x 844pt list of 74pt rows with the screens' sections; `onChange` runs as a screen's would.
    private func makeShownList(for viewModel: FilesViewModel,
                               onChange: @escaping (FileListPagingSection, UICollectionView) -> Void) -> (FileListPagingSection, UICollectionView) {
        let source = ListSource(viewModel)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: 390, height: 74)
        let list = UICollectionView(frame: window.bounds, collectionViewLayout: layout)
        list.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "row")
        list.dataSource = source
        window.addSubview(list)
        window.isHidden = false
        addTeardownBlock {
            window.isHidden = true
            _ = source
        }
        weak var shown: FileListPagingSection?
        let section = FileListPagingSection(collectionView: list, viewModel: { viewModel }, onChange: {
            if let shown { onChange(shown, list) }
        })
        shown = section
        source.section = section
        list.reloadData()
        list.layoutIfNeeded()
        return (section, list)
    }

    func testALaterPage_TakesTheSkeletonRowsPlace_WithoutAReload() {
        let size = FilesViewModel.childrenPageSize
        let later = FilesViewModel.nextChildrenPageSize
        // 19 files and a folder, then 59 files (the folder again is dropped), then 7 files.
        let viewModel = makeViewModel(responses: [fullPage, fullNextPage(from: size),
                                                  page(Array((size + later - 1)...(size + later + 5)), nextCursor: nil)])
        var addingDuringRedraw: [Bool] = []
        var inserted: [Bool] = []
        var landed: XCTestExpectation?
        let (section, list) = makeShownList(for: viewModel) { section, _ in
            addingDuringRedraw.append(section.isAddingPage)
            inserted.append(section.insertAddedPage())
            landed?.fulfill()
        }
        let rows = section.sectionIndex - 1
        // 20 rows, then 12 skeleton rows: at the bottom only skeleton rows show.
        let bottom = list.contentSize.height - list.bounds.height
        list.contentOffset.y = bottom
        list.layoutIfNeeded()

        let second = expectation(description: "second page")
        landed = second
        section.willDisplayItem(at: IndexPath(item: 0, section: section.sectionIndex))
        wait(for: [second], timeout: 5)

        XCTAssertEqual(addingDuringRedraw, [true], "a later page only adds rows after the listed ones")
        XCTAssertEqual(inserted, [true])
        XCTAssertFalse(section.isAddingPage)
        XCTAssertEqual(list.numberOfItems(inSection: rows), size + later - 1)
        XCTAssertEqual(list.numberOfItems(inSection: section.sectionIndex), 12, "more is due, so the skeleton rows stay under the new rows")
        XCTAssertEqual(list.contentOffset.y, bottom, "the list does not jump past the new rows")
        XCTAssertNotNil(list.cellForItem(at: IndexPath(item: size, section: rows)), "the first new row shows")
        XCTAssertFalse(section.insertAddedPage(), "only while a page is being added")

        let last = expectation(description: "last page")
        landed = last
        section.willDisplayItem(at: IndexPath(item: 0, section: section.sectionIndex))
        wait(for: [last], timeout: 5)

        XCTAssertEqual(inserted, [true, true], "the last page goes in the same way")
        XCTAssertEqual(list.numberOfItems(inSection: rows), size + later + 6)
        XCTAssertEqual(list.numberOfItems(inSection: section.sectionIndex), 0, "the skeleton rows go with the last page")
        XCTAssertEqual(section.footerContent, .counts(folders: 1, files: size + later + 5))
    }

    func testAPageThatCannotGoIn_IsLeftToAWholeReload() {
        let size = FilesViewModel.childrenPageSize
        let later = FilesViewModel.nextChildrenPageSize
        let emptyLastPage = try! FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self,
                                                                         from: Data(#"{ "items": [], "pagination": { "nextCursor": null } }"#.utf8))
        let viewModel = makeViewModel(responses: [fullPage, fullNextPage(from: size), fullNextPage(from: size + later - 1), .success(emptyLastPage)])
        var inserted: [Bool] = []
        var landed: XCTestExpectation?
        let (section, list) = makeShownList(for: viewModel) { section, list in
            let didInsert = section.insertAddedPage()
            inserted.append(didInsert)
            // As the screens do.
            if !didInsert { list.reloadData() }
            landed?.fulfill()
        }
        let land = { (name: String) in
            let page = self.expectation(description: name)
            landed = page
            section.willDisplayItem(at: IndexPath(item: 0, section: section.sectionIndex))
            self.wait(for: [page], timeout: 5)
        }

        viewModel.isSelecting = true
        land("in select mode")
        viewModel.isSelecting = false

        let window = list.window
        list.removeFromSuperview()
        land("off screen")
        window?.addSubview(list)

        viewModel.viewModels.removeAll()
        list.reloadData()
        land("into a list left empty")

        XCTAssertEqual(inserted, [false, false, false], "select mode, off screen, and a list the empty-folder view must cover")
        XCTAssertEqual(list.numberOfItems(inSection: section.sectionIndex - 1), 0)
        XCTAssertEqual(viewModel.childrenPagingState, .complete)
    }

    func testTheSkeletonFade_CoversOnlyTheNextReload() {
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 390, height: 844), collectionViewLayout: UICollectionViewFlowLayout())
        let section = FileListPagingSection(collectionView: collectionView, viewModel: { nil }, onChange: {})

        section.prepareForReload()
        XCTAssertNil(collectionView.layer.animation(forKey: kCATransition), "an ordinary reload does not fade")

        section.skeletonWillAppear()
        section.prepareForReload()
        XCTAssertEqual(collectionView.layer.animation(forKey: kCATransition)?.duration, 0.2)

        collectionView.layer.removeAllAnimations()
        section.prepareForReload()
        XCTAssertNil(collectionView.layer.animation(forKey: kCATransition), "one fade per request")

        section.skeletonWillDisappear()
        section.prepareForReload()
        XCTAssertEqual(collectionView.layer.animation(forKey: kCATransition)?.duration, 0.3)
    }

    func testTheSkeletonMinimumTime_IsSkippedOffScreen() {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let section = FileListPagingSection(collectionView: collectionView, viewModel: { nil }, onChange: {})
        section.skeletonWillAppear()

        var ran = false
        section.afterSkeletonMinimumTime { ran = true }

        XCTAssertTrue(ran, "tests and hidden screens never wait")
    }

    func testOnlyALabelledSkeleton_IsReadByVoiceOver() {
        let first = FileSkeletonCollectionViewCell(frame: .zero)
        first.configure(isGrid: false, accessibilityLabel: "LoadingMoreItems".localized())
        let other = FileSkeletonCollectionViewCell(frame: .zero)
        other.configure(isGrid: false, accessibilityLabel: nil)

        XCTAssertTrue(first.isAccessibilityElement)
        XCTAssertEqual(first.accessibilityLabel, "Loading more items")
        XCTAssertFalse(other.isAccessibilityElement)
        XCTAssertTrue(other.accessibilityElementsHidden)
    }
}
