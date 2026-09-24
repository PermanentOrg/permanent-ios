//
//  FilesViewModelPagingTests.swift
//  PermanentTests
//

import XCTest
@testable import Permanent

final class FilesViewModelPagingTests: XCTestCase {

    /// Scripted children requests: records every request and answers from `responses` in order.
    private final class PageServer {
        var requests: [(pageSize: Int, cursor: String?)] = []
        var responses: [Result<FolderChildrenV2Response, FilesViewModel.ChildrenPageFailure>] = []
        var heldCompletion: ((Result<FolderChildrenV2Response, FilesViewModel.ChildrenPageFailure>) -> Void)?
        var holdsNextRequest = false

        func attach(to viewModel: FilesViewModel) {
            viewModel.childrenPageV2Request = { [unowned self] _, pageSize, cursor, completion in
                self.requests.append((pageSize, cursor))
                if self.holdsNextRequest {
                    self.holdsNextRequest = false
                    self.heldCompletion = completion
                    return
                }
                completion(self.responses.removeFirst())
            }
        }
    }

    /// Falls back to a V1 listing that succeeds without the network.
    private final class V1SucceedingViewModel: MyFilesViewModel {
        override func performV1NavigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping ServerResponse) {
            handler(.success)
        }
    }

    /// The second V1 step answers with `leanStatus`, without the network.
    private final class LeanItemsStubViewModel: MyFilesViewModel {
        var leanStatus: RequestStatus = .success
        override func getLeanItems(params: GetLeanItemsParams, then handler: @escaping ServerResponse) {
            handler(leanStatus)
        }
    }

    /// Falls back to a V1 listing that fails without the network.
    private final class V1FailingViewModel: MyFilesViewModel {
        override func performV1NavigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping ServerResponse) {
            handler(.error(message: "offline"))
        }
    }

    private var navParams: NavigateMinParams { ("0001-test", 11, nil) }

    private func makeFolder(folderId: Int = 10, sort: String? = "date-descending") -> FileModel {
        let sortField = sort.map { ", \"sort\": \"\($0)\"" } ?? ""
        let json = """
        { "items": [ { "folderId": "\(folderId)", "displayName": "Folder \(folderId)", "type": "private",
          "status": "ok", "folderLinkId": "11", "archiveNumber": "0001-test"\(sortField) } ] }
        """
        let response = try! FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: Data(json.utf8))
        return FileModel(model: response.items![0], permissions: [.read], accessRole: .viewer)
    }

    /// Records with folderLinkIds `linkIds`, plus a folder when `withFolder` is set. `badLinkId` loses its archive number.
    private func page(_ linkIds: [Int], nextCursor: String?, withFolder: Bool = false, badLinkId: Int? = nil) -> Result<FolderChildrenV2Response, FilesViewModel.ChildrenPageFailure> {
        var items = linkIds.map { id in
            """
            { "recordId": "\(1000 + id)", "displayName": "photo-\(id).jpg", "archiveNumber": "\(id == badLinkId ? "" : "0001-\(id)")",
              "type": "type.record.image", "status": "ok", "folderLinkId": "\(id)" }
            """
        }
        if withFolder {
            items.append("""
            { "folderId": "500", "displayName": "Trips", "archiveNumber": "0001-500", "type": "private",
              "status": "ok", "folderLinkId": "500" }
            """)
        }
        let cursorField = nextCursor.map { "\"\($0)\"" } ?? "null"
        let json = "{ \"items\": [\(items.joined(separator: ","))], \"pagination\": { \"nextCursor\": \(cursorField) } }"
        return .success(try! FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: Data(json.utf8)))
    }

    private func enter(_ folder: FileModel, in viewModel: FilesViewModel, backNavigation: Bool = false) {
        if !backNavigation { viewModel.v2NavigationTarget = folder }
        let done = expectation(description: "folder listed")
        viewModel.navigateMin(params: navParams, backNavigation: backNavigation) { _ in done.fulfill() }
        wait(for: [done], timeout: 5)
    }

    private func loadNextPage(in viewModel: FilesViewModel) {
        let done = expectation(description: "next page")
        viewModel.loadNextChildrenPage { _ in done.fulfill() }
        wait(for: [done], timeout: 5)
    }

    // MARK: - First page

    func testFirstPage_AsksForTenAndKeepsTheCursor() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10")]

        enter(makeFolder(), in: viewModel)

        XCTAssertEqual(server.requests.first?.pageSize, 10)
        XCTAssertNil(server.requests.first?.cursor)
        XCTAssertEqual(viewModel.viewModels.count, 10)
        XCTAssertEqual(viewModel.childrenPagingState, .loadingMore)
    }

    func testFolderWithoutAKnownSort_ListsTheWholeFolderAtOnce() {
        // The phone must sort it, and a phone sort is only right over every child.
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10")]

        enter(makeFolder(sort: nil), in: viewModel)

        XCTAssertEqual(server.requests.first?.pageSize, FolderV2Endpoint.maxChildrenPageSize)
        XCTAssertEqual(viewModel.childrenPagingState, .complete)
    }

    func testRefreshingTheSameFolder_KeepsWhatIsOnScreen() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        let folder = makeFolder()
        server.responses = [page(Array(1...10), nextCursor: "10"), page([11, 12, 13], nextCursor: "13"), page(Array(1...13), nextCursor: "13")]

        enter(folder, in: viewModel)
        loadNextPage(in: viewModel)
        enter(folder, in: viewModel, backNavigation: true)

        XCTAssertEqual(server.requests.last?.pageSize, 20)
        XCTAssertEqual(viewModel.viewModels.count, 13)
        XCTAssertEqual(viewModel.childrenPagingState, .complete, "a short refresh page means the list is still whole")
    }

    // MARK: - Next pages

    func testNextPage_SendsTheCursor_DropsDuplicates_EndsOnAShortPage() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10"), page([10, 11, 12], nextCursor: "12")]

        enter(makeFolder(), in: viewModel)
        loadNextPage(in: viewModel)

        XCTAssertEqual(server.requests.last?.cursor, "10")
        XCTAssertEqual(server.requests.last?.pageSize, 10)
        XCTAssertEqual(viewModel.viewModels.map(\.folderLinkId), Array(1...12), "a child the server repeats is listed once")
        XCTAssertEqual(viewModel.childrenPagingState, .complete)
    }

    func testAnEmptyPage_EndsTheFolder() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10"), page([], nextCursor: nil)]

        enter(makeFolder(), in: viewModel)
        loadNextPage(in: viewModel)

        XCTAssertEqual(viewModel.viewModels.count, 10)
        XCTAssertEqual(viewModel.childrenPagingState, .complete)
    }

    func testAFailedPage_KeepsTheRows_AndRetryLoadsIt() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10"), .failure(.init(message: "offline")), page([11, 12], nextCursor: "12")]

        enter(makeFolder(), in: viewModel)
        loadNextPage(in: viewModel)

        XCTAssertEqual(viewModel.childrenPagingState, .failed)
        XCTAssertEqual(viewModel.viewModels.count, 10)

        let retried = expectation(description: "retry")
        viewModel.retryNextChildrenPage { _ in retried.fulfill() }
        wait(for: [retried], timeout: 5)

        XCTAssertEqual(server.requests.last?.cursor, "10", "the retry asks for the same page")
        XCTAssertEqual(viewModel.viewModels.count, 12)
        XCTAssertEqual(viewModel.childrenPagingState, .complete)
    }

    func testLeavingTheFolder_DropsAPageStillOnItsWay() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10"), page([50, 51], nextCursor: "51")]

        enter(makeFolder(folderId: 10), in: viewModel)
        server.holdsNextRequest = true
        var reportedChange: Bool?
        viewModel.loadNextChildrenPage { reportedChange = $0 }
        enter(makeFolder(folderId: 20), in: viewModel)

        let late = expectation(description: "late page")
        DispatchQueue.global().async {
            server.heldCompletion?(self.page([11, 12], nextCursor: "12"))
            DispatchQueue.main.async { late.fulfill() }
        }
        wait(for: [late], timeout: 5)

        XCTAssertEqual(viewModel.viewModels.map(\.folderLinkId), [50, 51])
        XCTAssertEqual(reportedChange, false)
    }

    func testLoadingPagesUntilAChildIsFound_StopsWhereItIs() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10"), page(Array(11...20), nextCursor: "20"), page([21], nextCursor: "21")]

        enter(makeFolder(), in: viewModel)
        let found = expectation(description: "found")
        var match: FileModel?
        viewModel.loadChildrenPages(until: { $0.folderLinkId == 15 }) { match = $0; found.fulfill() }
        wait(for: [found], timeout: 5)

        XCTAssertEqual(match?.folderLinkId, 15)
        XCTAssertEqual(server.requests.count, 2, "no page past the one holding the child")
    }

    // MARK: - V1 and a cleared stack

    func testV1Failsafe_ListsTheWholeFolder() {
        let viewModel = V1SucceedingViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10"), .failure(.init(message: "offline"))]

        enter(makeFolder(folderId: 10), in: viewModel)
        XCTAssertEqual(viewModel.childrenPagingState, .loadingMore)
        enter(makeFolder(folderId: 20), in: viewModel)

        XCTAssertEqual(viewModel.childrenPagingState, .complete)
    }

    func testEmptyingTheStack_EndsPaging() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10")]

        enter(makeFolder(), in: viewModel)
        viewModel.navigationStack.removeAll()

        XCTAssertEqual(viewModel.childrenPagingState, .complete)
    }

    func testTheFirstPageSkeleton_HidesThePreviousFolder() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...3), nextCursor: "3", withFolder: true)]
        enter(makeFolder(), in: viewModel)

        viewModel.isLoadingFirstPage = true

        XCTAssertTrue(viewModel.syncedViewModels.isEmpty)
        XCTAssertFalse(viewModel.shouldDisplayBackgroundView, "no empty-folder message under the skeleton")
    }

    // MARK: - Flows that need the whole folder

    func testAPasteIntoAPagedFolder_WaitsUntilThePastedRowIsListed() {
        // The paste check counts children, so the screen lists the folder whole before pasting.
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        let folder = makeFolder()
        server.responses = [page(Array(1...10), nextCursor: "10"), page(Array(1...25), nextCursor: "25"), page(Array(1...25), nextCursor: "25")]
        enter(folder, in: viewModel)
        let listed = expectation(description: "whole folder")
        viewModel.listWholeFolder { _ in listed.fulfill() }
        wait(for: [listed], timeout: 5)

        viewModel.expectPastedItems([viewModel.viewModels[0]], destination: folder)
        enter(folder, in: viewModel, backNavigation: true)

        XCTAssertEqual(server.requests.last?.pageSize, FolderV2Endpoint.maxChildrenPageSize, "the settle refetch lists the whole folder")
        XCTAssertTrue(viewModel.isAwaitingPastedItems, "25 rows, and the paste is still missing")
    }

    func testAPickedSortTheServerDoesNotHold_ListsTheWholeFolder() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        let folder = makeFolder(sort: "date-descending")
        server.responses = [page(Array(1...10), nextCursor: "10"), page(Array(1...12), nextCursor: "12")]

        enter(folder, in: viewModel)
        viewModel.activeSortOption = .nameDescending
        enter(folder, in: viewModel, backNavigation: true)

        XCTAssertEqual(server.requests.last?.pageSize, FolderV2Endpoint.maxChildrenPageSize)
        XCTAssertEqual(viewModel.childrenPagingState, .complete)
        XCTAssertEqual(viewModel.viewModels.first?.name, "photo-9.jpg", "sorted on the phone by name, descending")
    }

    func testListingTheWholeFolder_AsksForEveryChildOnce() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10"), page(Array(1...25), nextCursor: "25")]
        enter(makeFolder(), in: viewModel)

        let listed = expectation(description: "whole folder")
        viewModel.listWholeFolder { _ in listed.fulfill() }
        wait(for: [listed], timeout: 5)

        XCTAssertEqual(server.requests.last?.pageSize, FolderV2Endpoint.maxChildrenPageSize)
        XCTAssertEqual(viewModel.viewModels.count, 25)
        XCTAssertEqual(viewModel.childrenPagingState, .complete)
    }

    // MARK: - Contract breaks on later pages

    func testABadChildOnALaterPage_ListsTheWholeFolder() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10"), page(Array(11...20), nextCursor: "20", badLinkId: 15), page(Array(1...24), nextCursor: "24")]

        enter(makeFolder(), in: viewModel)
        loadNextPage(in: viewModel)

        XCTAssertEqual(server.requests.last?.pageSize, FolderV2Endpoint.maxChildrenPageSize, "the same cursor would fail again")
        XCTAssertEqual(viewModel.viewModels.count, 24)
        XCTAssertEqual(viewModel.childrenPagingState, .complete)
    }

    func testABadChildWhoseReListAlsoFails_WaitsForARetry() {
        let viewModel = V1FailingViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10"), page(Array(11...20), nextCursor: "20", badLinkId: 15), .failure(.init(message: "offline"))]

        enter(makeFolder(), in: viewModel)
        loadNextPage(in: viewModel)
        let requestsAfterFailure = server.requests.count
        loadNextPage(in: viewModel)

        XCTAssertEqual(viewModel.childrenPagingState, .failed)
        XCTAssertEqual(viewModel.viewModels.count, 10)
        XCTAssertEqual(server.requests.count, requestsAfterFailure, "no request until the user taps retry")
    }

    // MARK: - One request at a time

    func testTwoNextPageCalls_SendOneRequest() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10")]
        enter(makeFolder(), in: viewModel)

        server.holdsNextRequest = true
        viewModel.loadNextChildrenPage { _ in }
        var secondChanged: Bool?
        viewModel.loadNextChildrenPage { secondChanged = $0 }

        XCTAssertEqual(server.requests.count, 2, "the first page and one next page")
        XCTAssertEqual(secondChanged, false)
    }

    func testARefresh_DropsTheNextPageOnItsWay() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        let folder = makeFolder()
        server.responses = [page(Array(1...10), nextCursor: "10"), page(Array(1...20), nextCursor: "20")]
        enter(folder, in: viewModel)

        server.holdsNextRequest = true
        var reportedChange: Bool?
        viewModel.loadNextChildrenPage { reportedChange = $0 }
        enter(folder, in: viewModel, backNavigation: true)

        let late = expectation(description: "late page")
        DispatchQueue.global().async {
            server.heldCompletion?(self.page([11, 12], nextCursor: "12"))
            DispatchQueue.main.async { late.fulfill() }
        }
        wait(for: [late], timeout: 5)

        XCTAssertEqual(viewModel.viewModels.map(\.folderLinkId), Array(1...20))
        XCTAssertEqual(reportedChange, false)
    }

    func testNoNextPageStarts_WhileAFirstPageIsOnItsWay() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        let folder = makeFolder()
        server.responses = [page(Array(1...10), nextCursor: "10")]
        enter(folder, in: viewModel)

        server.holdsNextRequest = true
        viewModel.navigateMin(params: navParams, backNavigation: true) { _ in }
        var changed: Bool?
        viewModel.loadNextChildrenPage { changed = $0 }

        XCTAssertEqual(changed, false)
        XCTAssertEqual(server.requests.count, 2, "the first page and the refresh, no next page")
    }

    func testALateFolderListing_DoesNotLandOnceNoFolderIsOnScreen() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page([1, 2, 3], nextCursor: nil)]
        enter(makeFolder(), in: viewModel)

        server.holdsNextRequest = true
        let done = expectation(description: "refresh settled")
        viewModel.navigateMin(params: navParams, backNavigation: true) { _ in done.fulfill() }
        // The share list or the search results replace the folder while its refresh is on the way.
        viewModel.navigationStack.removeAll()
        viewModel.viewModels = []

        server.heldCompletion?(page(Array(1...10), nextCursor: "10"))
        wait(for: [done], timeout: 5)

        XCTAssertTrue(viewModel.viewModels.isEmpty, "the folder's rows stay off the list that replaced it")
        XCTAssertEqual(viewModel.childrenPagingState, .complete, "and none of its pages are due")
    }

    func testRetry_DoesNothingUnlessAPageFailed() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10")]
        enter(makeFolder(), in: viewModel)

        var changed: Bool?
        viewModel.retryNextChildrenPage { changed = $0 }

        XCTAssertEqual(changed, false)
        XCTAssertEqual(server.requests.count, 1)
    }

    func testLoadingPagesUntilAMatch_ReturnsNothingWhenAPageFails() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10"), .failure(.init(message: "offline"))]
        enter(makeFolder(), in: viewModel)

        let done = expectation(description: "search ends")
        var match: FileModel?
        viewModel.loadChildrenPages(until: { $0.folderLinkId == 99 }) { match = $0; done.fulfill() }
        wait(for: [done], timeout: 5)

        XCTAssertNil(match)
        XCTAssertEqual(viewModel.childrenPagingState, .failed)
    }

    // MARK: - What the screen shows

    func testNoEmptyFolderView_WhileMorePagesAreDue() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10")]
        enter(makeFolder(), in: viewModel)

        viewModel.viewModels.removeAll()

        XCTAssertFalse(viewModel.shouldDisplayBackgroundView, "rows deleted from a paged folder are not the whole folder")
    }

    func testTheSelectAllCheckbox_IsFullOnlyOverTheWholeFolder() {
        let viewModel = FilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10"), page([11, 12], nextCursor: "12")]
        enter(makeFolder(), in: viewModel)
        viewModel.isSelecting = true
        viewModel.selectedFiles = viewModel.viewModels
        viewModel.updateCheckboxState()
        XCTAssertEqual(viewModel.checkboxState, .partial, "every loaded row is not every child")

        loadNextPage(in: viewModel)
        XCTAssertEqual(viewModel.checkboxState, .partial)

        viewModel.selectedFiles = viewModel.viewModels
        viewModel.updateCheckboxState()
        XCTAssertEqual(viewModel.checkboxState, .selected)
    }

    func testTheHeaderOverTheSkeleton_NamesTheSortOfTheFolderBeingEntered() {
        let viewModel = SharedFilesViewModel()
        viewModel.v2NavigationTarget = makeFolder(sort: "date-descending")
        XCTAssertEqual(viewModel.title(forSection: FileListType.synced.rawValue), "", "the share list has no sort header")

        viewModel.isLoadingFirstPage = true

        XCTAssertEqual(viewModel.title(forSection: FileListType.synced.rawValue), SortOption.dateDescending.title)
    }

    func testABackPreview_NamesTheParentsSortNotTheChilds() {
        let viewModel = MyFilesViewModel()
        viewModel.navigationStack = [makeFolder(folderId: 1, sort: "date-descending"), makeFolder(folderId: 2, sort: nil)]

        viewModel.beginBackPreview()
        XCTAssertEqual(viewModel.title(forSection: FileListType.synced.rawValue), SortOption.dateDescending.title)

        XCTAssertTrue(viewModel.endBackPreview(), "no other load, so the folder's rows come back")
        XCTAssertFalse(viewModel.isLoadingFirstPage)
    }

    func testABackPreview_StopsApplyingOnceAnotherLoadOrAnotherFolderTakesOver() {
        let viewModel = MyFilesViewModel()
        viewModel.navigationStack = [makeFolder(folderId: 1), makeFolder(folderId: 2)]
        viewModel.beginBackPreview()
        XCTAssertTrue(viewModel.backPreviewStillApplies)

        viewModel.beginFirstPageLoad()
        XCTAssertFalse(viewModel.backPreviewStillApplies, "a load started under the finger")
        viewModel.endFirstPageLoad()
        XCTAssertTrue(viewModel.backPreviewStillApplies)

        viewModel.navigationStack.removeLast()
        XCTAssertFalse(viewModel.backPreviewStillApplies, "the folder the swipe began in has gone")
        viewModel.endBackPreview()
        XCTAssertFalse(viewModel.backPreviewStillApplies)
    }

    func testASharesBackPreview_LetsAShareListThatLoadsUnderItShow() {
        let viewModel = SharedFilesViewModel()
        viewModel.navigationStack = [makeFolder(folderId: 1)]
        viewModel.beginBackPreview()

        // An archive switch empties the history and reloads the share list while the finger is down.
        viewModel.navigationStack.removeAll()
        viewModel.beginShareListLoad()
        XCTAssertTrue(viewModel.showsShareList)

        viewModel.endBackPreview()
        XCTAssertTrue(viewModel.showsShareList)
    }

    /// Records whether the V1 route ran, without the network.
    private final class LinkedSharedFilesViewModel: SharedFilesViewModel {
        var v1Entries = 0
        override func performV1NavigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping ServerResponse) {
            v1Entries += 1
            handler(.success)
        }
    }

    private func openLinkedFolder(details: FolderV2Data?, in viewModel: LinkedSharedFilesViewModel) {
        viewModel.linkedFolderId = 77
        viewModel.folderV2Request = { folderId, completion in
            XCTAssertEqual(folderId, "77")
            completion(details)
        }
        let done = expectation(description: "linked folder entered")
        viewModel.navigateMin(params: navParams, backNavigation: false) { _ in done.fulfill() }
        wait(for: [done], timeout: 5)
    }

    func testAShareLinksFolder_OpensOnThePagedRouteWithTheServersRole() {
        let viewModel = LinkedSharedFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10")]

        openLinkedFolder(details: FolderV2Data(folderId: "77", displayName: "Trips", folderLinkId: "11", accessRole: "editor"), in: viewModel)

        XCTAssertEqual(viewModel.v1Entries, 0)
        XCTAssertEqual(server.requests.first?.pageSize, FilesViewModel.childrenPageSize, "a first page, not the whole folder")
        XCTAssertEqual(viewModel.childrenPagingState, .loadingMore)
        XCTAssertEqual(viewModel.navigationStack.last?.folderId, 77)
        XCTAssertEqual(viewModel.navigationStack.last?.accessRole, .editor)
    }

    func testAShareLinksFolderWithoutDetails_OpensOnTheV1RouteAsBefore() {
        let viewModel = LinkedSharedFilesViewModel()
        openLinkedFolder(details: nil, in: viewModel)
        XCTAssertEqual(viewModel.v1Entries, 1)
    }

    func testDetailsForAnotherFolderLink_AreNotUsed() {
        let viewModel = LinkedSharedFilesViewModel()
        openLinkedFolder(details: FolderV2Data(folderId: "77", folderLinkId: "999", accessRole: "owner"), in: viewModel)
        XCTAssertEqual(viewModel.v1Entries, 1, "the details must name the folder link being opened")
    }

    func testDetailsWithoutARole_FailClosedToViewer() {
        let viewModel = LinkedSharedFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page([1, 2], nextCursor: nil)]

        openLinkedFolder(details: FolderV2Data(folderId: "77", folderLinkId: "11"), in: viewModel)

        XCTAssertEqual(viewModel.navigationStack.last?.accessRole, .viewer)
        XCTAssertFalse(viewModel.navigationStack.last?.permissions.contains(.edit) ?? true)
    }

    func testTheShareListSkeleton_HasNoSortHeader() {
        let viewModel = SharedFilesViewModel()
        viewModel.beginShareListLoad()

        XCTAssertEqual(viewModel.title(forSection: FileListType.synced.rawValue), "")
    }

    func testTheHeaderOverARootSkeleton_KeepsTheCurrentSortUntilTheRootNamesItsOwn() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.holdsNextRequest = true
        viewModel.activeSortOption = .dateAscending
        viewModel.beginFirstPageLoad()
        XCTAssertEqual(viewModel.title(forSection: FileListType.synced.rawValue), SortOption.dateAscending.title, "no folder yet, so the current sort stays")

        let told = expectation(forNotification: FilesViewModel.childrenDidChangeNotification, object: viewModel)
        viewModel.v2NavigationTarget = makeFolder(sort: "date-descending")
        viewModel.navigateMin(params: navParams, backNavigation: false) { _ in }
        wait(for: [told], timeout: 5)

        XCTAssertEqual(viewModel.title(forSection: FileListType.synced.rawValue), SortOption.dateDescending.title)
    }

    func testOverlappingFirstPageLoads_EndWithTheLastOne() {
        let viewModel = MyFilesViewModel()
        viewModel.beginFirstPageLoad()
        viewModel.beginFirstPageLoad()

        XCTAssertFalse(viewModel.endFirstPageLoad())
        XCTAssertTrue(viewModel.isLoadingFirstPage)
        XCTAssertTrue(viewModel.endFirstPageLoad())
        XCTAssertFalse(viewModel.isLoadingFirstPage)
    }

    func testAFullPageOfRepeats_ListsTheWholeFolderInsteadOfAskingAgain() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10"), page(Array(1...10), nextCursor: "10"), page(Array(1...14), nextCursor: "14")]

        enter(makeFolder(), in: viewModel)
        loadNextPage(in: viewModel)

        XCTAssertEqual(server.requests.last?.pageSize, FolderV2Endpoint.maxChildrenPageSize)
        XCTAssertEqual(viewModel.viewModels.count, 14)
        XCTAssertEqual(viewModel.childrenPagingState, .complete)
    }

    func testRetry_WhileAFirstPageIsOnItsWay_KeepsTheRetryFooter() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        let folder = makeFolder()
        server.responses = [page(Array(1...10), nextCursor: "10"), .failure(.init(message: "offline"))]
        enter(folder, in: viewModel)
        loadNextPage(in: viewModel)

        server.holdsNextRequest = true
        viewModel.navigateMin(params: navParams, backNavigation: true) { _ in }
        var changed: Bool?
        viewModel.retryNextChildrenPage { changed = $0 }

        XCTAssertEqual(changed, false)
        XCTAssertEqual(viewModel.childrenPagingState, .failed)
    }

    func testAFailedRefreshThatDroppedAPage_AsksTheScreenToLoadItAgain() {
        let viewModel = V1FailingViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        let folder = makeFolder()
        server.responses = [page(Array(1...10), nextCursor: "10"), .failure(.init(message: "offline"))]
        enter(folder, in: viewModel)
        server.holdsNextRequest = true
        viewModel.loadNextChildrenPage { _ in }

        let told = expectation(forNotification: FilesViewModel.childrenDidChangeNotification, object: viewModel)
        enter(folder, in: viewModel, backNavigation: true)
        wait(for: [told], timeout: 5)

        XCTAssertEqual(viewModel.childrenPagingState, .loadingMore)
    }

    func testDeletingTheCursorRow_HandsTheCursorToTheLastRowLeft() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10"), .failure(.init(message: "offline")), page([11], nextCursor: "11")]
        enter(makeFolder(), in: viewModel)
        loadNextPage(in: viewModel)

        viewModel.removeSyncedFiles([viewModel.viewModels[9]])
        let retried = expectation(description: "retry")
        viewModel.retryNextChildrenPage { _ in retried.fulfill() }
        wait(for: [retried], timeout: 5)

        XCTAssertEqual(server.requests.last?.cursor, "9")
    }

    func testAPageThatLands_TellsTheScreen() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page(Array(1...10), nextCursor: "10"), page([11], nextCursor: "11")]
        enter(makeFolder(), in: viewModel)

        let posted = expectation(forNotification: FilesViewModel.childrenDidChangeNotification, object: viewModel)
        viewModel.loadNextChildrenPage { _ in }
        wait(for: [posted], timeout: 5)
    }

    // MARK: - V1 listing

    func testAFailedV1Listing_LeavesTheHistoryAndSortAlone() {
        let viewModel = LeanItemsStubViewModel()
        viewModel.leanStatus = .error(message: "offline")
        let entered = makeFolder(folderId: 30, sort: "date-descending")

        var status: RequestStatus?
        viewModel.listV1Folder(entering: entered, folderId: 30, savedSort: .dateDescending, params: ("0001-test", [1, 2], 11)) { status = $0 }

        XCTAssertEqual(status, .error(message: "offline"))
        XCTAssertTrue(viewModel.navigationStack.isEmpty, "the folder on screen stays the current folder")
        XCTAssertEqual(viewModel.activeSortOption, .nameAscending)
    }

    func testASuccessfulV1Listing_EntersTheFolderAndAdoptsItsSort() {
        let viewModel = LeanItemsStubViewModel()
        let entered = makeFolder(folderId: 30, sort: "date-descending")

        viewModel.listV1Folder(entering: entered, folderId: 30, savedSort: .dateDescending, params: ("0001-test", [1, 2], 11)) { _ in }

        XCTAssertEqual(viewModel.navigationStack.last?.folderId, 30)
        XCTAssertEqual(viewModel.activeSortOption, .dateDescending)
    }

    func testTheShareList_WaitsWhileAFolderIsOpenOrBeingEntered() {
        let viewModel = SharedFilesViewModel()
        XCTAssertTrue(viewModel.showsShareList)

        viewModel.isLoadingFirstPage = true
        XCTAssertFalse(viewModel.showsShareList)

        viewModel.isLoadingFirstPage = false
        viewModel.navigationStack = [makeFolder()]
        XCTAssertFalse(viewModel.showsShareList)
    }

    func testTheShareListLoadingUnderItsOwnSkeleton_StillShows() {
        let viewModel = SharedFilesViewModel()

        viewModel.beginShareListLoad()
        XCTAssertTrue(viewModel.isLoadingFirstPage)
        XCTAssertTrue(viewModel.showsShareList, "the share list's own skeleton does not hold it back")

        viewModel.beginFirstPageLoad()
        XCTAssertFalse(viewModel.showsShareList, "a folder being entered at the same time wins")

        viewModel.endFirstPageLoad()
        XCTAssertTrue(viewModel.endShareListLoad())
        XCTAssertFalse(viewModel.isLoadingFirstPage)
    }

    // MARK: - Late V1 replies

    /// A V1 reply for folder `folderId`, whose children are records with the given folderLinkIds.
    private func v1Listing(folderId: Int, folderLinkId: Int, sort: String = "sort.alphabetical_asc", childLinkIds: [Int]) -> Result<NavigateMinResponse, FilesViewModel.ChildrenPageFailure> {
        let children = childLinkIds.map { id in
            """
            { "folder_linkId": \(id), "recordId": \(2000 + id), "displayName": "v1-\(id)", "type": "type.record.image", "archiveNbr": "0001-v1\(id)" }
            """
        }
        let json = """
        { "isSuccessful": true, "Results": [ { "data": [ { "FolderVO": {
          "folderId": \(folderId), "folder_linkId": \(folderLinkId), "archiveNbr": "0001-test", "displayName": "V1 folder", "sort": "\(sort)",
          "ChildItemVOs": [\(children.joined(separator: ","))] } } ] } ] }
        """
        return .success(try! JSONDecoder().decode(NavigateMinResponse.self, from: Data(json.utf8)))
    }

    func testALateV1RefreshReply_LeavesTheFolderOpenedSinceAlone() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        let folderA = makeFolder(folderId: 10)
        let folderB = makeFolder(folderId: 20)
        server.responses = [page(Array(1...10), nextCursor: "10"), .failure(.init(message: "offline")), page(Array(50...59), nextCursor: "59")]
        enter(folderA, in: viewModel)

        // A's refresh fails on V2 and its V1 reply is held back.
        var heldReply: ((Result<NavigateMinResponse, FilesViewModel.ChildrenPageFailure>) -> Void)?
        let reachedV1 = expectation(description: "V1 leg started")
        viewModel.navigateMinV1Request = { _, completion in
            heldReply = completion
            reachedV1.fulfill()
        }
        var leanRequests = 0
        viewModel.leanItemsV1Request = { _, completion in
            leanRequests += 1
            completion(self.v1Listing(folderId: 10, folderLinkId: 11, childLinkIds: [900, 901]))
        }
        var refreshStatus: RequestStatus?
        viewModel.navigateMin(params: navParams, backNavigation: true) { refreshStatus = $0 }
        wait(for: [reachedV1], timeout: 5)

        enter(folderB, in: viewModel)
        heldReply?(v1Listing(folderId: 10, folderLinkId: 11, childLinkIds: [900, 901]))

        XCTAssertEqual(refreshStatus, .success, "a superseded listing completes quietly")
        XCTAssertEqual(viewModel.viewModels.map(\.folderLinkId), Array(50...59), "B's rows stay")
        XCTAssertEqual(viewModel.navigationStack.map(\.folderId), [10, 20])
        XCTAssertEqual(viewModel.childrenPagingState, .loadingMore, "B's paging is untouched")
        XCTAssertEqual(leanRequests, 0, "no second request for a folder no longer on its way")
    }

    func testALateV1RowsReply_NeitherEntersItsFolderNorAdoptsItsSort() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        let folderB = makeFolder(folderId: 20, sort: "date-descending")
        server.responses = [page(Array(1...10), nextCursor: "10"), page(Array(50...59), nextCursor: "59")]
        enter(makeFolder(folderId: 10), in: viewModel)

        // A link with no V2 target goes straight to V1; its rows request is held back.
        viewModel.navigateMinV1Request = { _, completion in
            completion(self.v1Listing(folderId: 40, folderLinkId: 41, childLinkIds: [900]))
        }
        var heldRows: ((Result<NavigateMinResponse, FilesViewModel.ChildrenPageFailure>) -> Void)?
        viewModel.leanItemsV1Request = { _, completion in heldRows = completion }
        var linkStatus: RequestStatus?
        viewModel.navigateMin(params: ("0001-test", 41, nil), backNavigation: false) { linkStatus = $0 }

        enter(folderB, in: viewModel)
        heldRows?(v1Listing(folderId: 40, folderLinkId: 41, childLinkIds: [900]))

        XCTAssertEqual(linkStatus, .success)
        XCTAssertEqual(viewModel.viewModels.map(\.folderLinkId), Array(50...59))
        XCTAssertEqual(viewModel.navigationStack.map(\.folderId), [10, 20], "the linked folder never joins the history")
        XCTAssertEqual(viewModel.activeSortOption, .dateDescending, "B's sort stays")
    }

    func testACurrentV1Listing_StillCommits() {
        let viewModel = MyFilesViewModel()
        viewModel.navigateMinV1Request = { _, completion in
            completion(self.v1Listing(folderId: 40, folderLinkId: 41, childLinkIds: [900, 901]))
        }
        viewModel.leanItemsV1Request = { _, completion in
            completion(self.v1Listing(folderId: 40, folderLinkId: 41, childLinkIds: [900, 901]))
        }

        var status: RequestStatus?
        viewModel.navigateMin(params: ("0001-test", 41, nil), backNavigation: false) { status = $0 }

        XCTAssertEqual(status, .success)
        XCTAssertEqual(viewModel.viewModels.map(\.folderLinkId), [900, 901])
        XCTAssertEqual(viewModel.navigationStack.last?.folderId, 40)
        XCTAssertEqual(viewModel.childrenPagingState, .complete)
    }

    // MARK: - Sizes and footer text

    func testFirstPageSize_RoundsUpAndLeavesRoomForOneMore() {
        XCTAssertEqual(FilesViewModel.firstPageSize(keeping: 0), 10)
        XCTAssertEqual(FilesViewModel.firstPageSize(keeping: 9), 10)
        XCTAssertEqual(FilesViewModel.firstPageSize(keeping: 10), 20)
        XCTAssertEqual(FilesViewModel.firstPageSize(keeping: 37), 40)
    }

    func testLoadedCounts_SplitFoldersFromFiles() {
        let viewModel = MyFilesViewModel()
        let server = PageServer()
        server.attach(to: viewModel)
        server.responses = [page([1, 2, 3], nextCursor: "3", withFolder: true)]

        enter(makeFolder(), in: viewModel)

        XCTAssertEqual(viewModel.loadedFolderCount, 1)
        XCTAssertEqual(viewModel.loadedFileCount, 3)
    }

    func testFooterCounts_UseSingularAndPlural() {
        XCTAssertEqual(FileListStatusFooterView.countsText(folders: 4, files: 3), "4 Folders, 3 Files")
        XCTAssertEqual(FileListStatusFooterView.countsText(folders: 1, files: 1), "1 Folder, 1 File")
        XCTAssertEqual(FileListStatusFooterView.countsText(folders: 0, files: 2), "0 Folders, 2 Files")
    }
}
