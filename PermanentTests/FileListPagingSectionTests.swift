//
//  FileListPagingSectionTests.swift
//  PermanentTests
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

    private func makeSection(for viewModel: FilesViewModel, onChange: @escaping () -> Void = {}) -> FileListPagingSection {
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 390, height: 844), collectionViewLayout: UICollectionViewFlowLayout())
        addTeardownBlock { _ = collectionView }
        return FileListPagingSection(collectionView: collectionView, viewModel: { viewModel }, onChange: onChange)
    }

    func testTheSectionComesAfterTheViewModelsOwn() {
        let viewModel = MyFilesViewModel()
        XCTAssertEqual(makeSection(for: viewModel).sectionIndex, viewModel.numberOfSections)
    }

    func testTheFirstPage_ShowsAScreenOfSkeletonsAndNoFooter() {
        let viewModel = makeViewModel(responses: [page(Array(1...9), nextCursor: "9")])
        let section = makeSection(for: viewModel)

        viewModel.isLoadingFirstPage = true

        XCTAssertEqual(section.numberOfItems(isGrid: false), 8)
        XCTAssertEqual(section.numberOfItems(isGrid: true), 6)
        XCTAssertEqual(section.footerContent, .hidden)
    }

    func testMorePagesDue_ShowThreeSkeletonRowsAndNoFooter() {
        let viewModel = makeViewModel(responses: [page(Array(1...9), nextCursor: "9")])
        let section = makeSection(for: viewModel)

        XCTAssertEqual(viewModel.childrenPagingState, .loadingMore)
        XCTAssertEqual(section.numberOfItems(isGrid: false), 3)
        XCTAssertEqual(section.numberOfItems(isGrid: true), 2)
        XCTAssertEqual(section.footerContent, .hidden)
    }

    func testAFailedPage_KeepsTheSkeletonRowsAndShowsTheRetryFooter() {
        let viewModel = makeViewModel(responses: [page(Array(1...9), nextCursor: "9"), .failure(.init(message: "offline"))])
        let section = makeSection(for: viewModel)
        let loaded = expectation(description: "page")
        viewModel.loadNextChildrenPage { _ in loaded.fulfill() }
        wait(for: [loaded], timeout: 5)

        XCTAssertEqual(section.numberOfItems(isGrid: false), 3)
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

        viewModel.viewModels.removeAll()
        XCTAssertEqual(section.footerContent, .hidden, "an empty folder shows its empty view instead")

        viewModel.navigationStack.removeAll()
        XCTAssertEqual(section.footerContent, .hidden, "the share list and search results are not a folder")
    }

    func testSkeletonsComingIntoView_LoadTheNextPageOnlyWhileOneIsDue() {
        var requests = 0
        let viewModel = makeViewModel(responses: [page(Array(1...9), nextCursor: "9"), .failure(.init(message: "offline"))])
        let answer = viewModel.childrenPageV2Request
        viewModel.childrenPageV2Request = { folderId, pageSize, cursor, completion in
            requests += 1
            answer?(folderId, pageSize, cursor, completion)
        }
        let changed = expectation(description: "screen told")
        let section = makeSection(for: viewModel, onChange: { changed.fulfill() })

        section.willDisplayItem(at: IndexPath(item: 0, section: section.sectionIndex - 1))
        XCTAssertEqual(requests, 0, "rows of other sections never ask")

        section.willDisplayItem(at: IndexPath(item: 0, section: section.sectionIndex))
        wait(for: [changed], timeout: 5)
        XCTAssertEqual(requests, 1)

        section.willDisplayItem(at: IndexPath(item: 0, section: section.sectionIndex))
        XCTAssertEqual(requests, 1, "a failed page waits for the retry button")
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
