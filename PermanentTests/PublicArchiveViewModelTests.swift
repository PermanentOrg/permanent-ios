//
//  PublicArchiveViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.05.2026.
//

import XCTest
@testable import Permanent

/// Public gallery view model with the V1 navigation leg stubbed out. `performV1NavigateMin`
/// issues a real network request, which a unit test must not do: on a logged-in simulator it
/// carries a Bearer token, and a 401 posts `sessionExpiredNotificationName` → an async
/// `logout()` that clears the session other tests depend on. Recording the call is also a
/// stronger assertion than reading the process-wide `lastNavigationSource` string.
final class StubV1GalleryViewModel: PublicArchiveViewModel {
    var v1NavigateMinCallCount = 0
    var v1NavigateMinBackNavigation: [Bool] = []
    /// What the stubbed V1 leg reports back; `.success` mirrors a healthy legacy response.
    var v1NavigateMinResult: RequestStatus = .success

    override func performV1NavigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping ServerResponse) {
        v1NavigateMinCallCount += 1
        v1NavigateMinBackNavigation.append(backNavigation)
        handler(v1NavigateMinResult)
    }
}

final class PublicArchiveViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
        #if DEBUG
        // `lastNavigationSource` is a process-wide static shared by every screen, so a
        // leftover "v1" from an earlier test would make the assertions below pass without
        // this run's navigation having reached the V1 path at all. Reset to a value that
        // neither path ever writes.
        FilesViewModel.lastNavigationSource = "none"
        #endif
    }

    private func makeRecordFile(name: String = "photo.jpg") -> FileModel {
        return FileModel(
            name: name,
            recordId: 100,
            folderLinkId: 1,
            archiveNbr: "0001-0000",
            type: "type.record.image",
            permissions: [.read]
        )
    }

    private func makeFolderFile(name: String = "My Folder") -> FileModel {
        return FileModel(
            name: name,
            recordId: 0,
            folderLinkId: 2,
            archiveNbr: "0001-0000",
            type: "type.folder.public",
            permissions: [.read]
        )
    }

    // MARK: - currentFolderIsRoot

    func testCurrentFolderIsRoot_EmptyStack_False() {
        let vm = PublicArchiveViewModel()
        XCTAssertFalse(vm.currentFolderIsRoot)
    }

    func testCurrentFolderIsRoot_OneItem_True() {
        let vm = PublicArchiveViewModel()
        vm.navigationStack.append(makeFolderFile())
        XCTAssertTrue(vm.currentFolderIsRoot)
    }

    func testCurrentFolderIsRoot_TwoItems_False() {
        let vm = PublicArchiveViewModel()
        vm.navigationStack.append(makeFolderFile())
        vm.navigationStack.append(makeFolderFile())
        XCTAssertFalse(vm.currentFolderIsRoot)
    }

    // MARK: - numberOfSections

    func testNumberOfSections_IsOne() {
        let vm = PublicArchiveViewModel()
        XCTAssertEqual(vm.numberOfSections, 1)
    }

    // MARK: - numberOfRowsInSection

    func testNumberOfRows_MatchesSyncedViewModels() {
        let vm = PublicArchiveViewModel()
        vm.viewModels.append(makeRecordFile())
        vm.viewModels.append(makeRecordFile())
        XCTAssertEqual(vm.numberOfRowsInSection(0), 2)
    }

    func testNumberOfRows_Empty_ReturnsZero() {
        let vm = PublicArchiveViewModel()
        XCTAssertEqual(vm.numberOfRowsInSection(0), 0)
    }

    // MARK: - heightForSection

    func testHeightForSection_ReturnsZero() {
        let vm = PublicArchiveViewModel()
        XCTAssertEqual(vm.heightForSection(0), 0)
        XCTAssertEqual(vm.heightForSection(1), 0)
    }

    // MARK: - fileForRowAt

    func testFileForRowAt_Section0_ReturnsCorrectFile() {
        let vm = PublicArchiveViewModel()
        let file = makeRecordFile(name: "public_file.jpg")
        vm.viewModels.append(file)
        let indexPath = IndexPath(row: 0, section: 0)
        let result = vm.fileForRowAt(indexPath: indexPath)
        XCTAssertEqual(result.name, "public_file.jpg")
    }

    // MARK: - currentArchive property

    func testCurrentArchive_InitiallyNil() {
        let vm = PublicArchiveViewModel()
        XCTAssertNil(vm.currentArchive)
    }

    func testCurrentArchive_CanBeSet() {
        let vm = PublicArchiveViewModel()
        let archive = ArchiveVOData.mock()
        vm.currentArchive = archive
        XCTAssertEqual(vm.currentArchive?.archiveID, 1)
    }

    // MARK: - publicURL

    func testPublicURL_NilCurrentArchive_ReturnsNil() {
        let vm = PublicArchiveViewModel()
        let file = makeRecordFile()
        XCTAssertNil(vm.publicURL(forFile: file))
    }

    func testPublicURL_NilCurrentFolder_ReturnsNil() {
        let vm = PublicArchiveViewModel()
        vm.currentArchive = ArchiveVOData.mock()
        let file = makeRecordFile()
        XCTAssertNil(vm.publicURL(forFile: file))
    }

    func testPublicURL_FolderFile_ContainsArchiveInURL() {
        let vm = PublicArchiveViewModel()
        vm.currentArchive = ArchiveVOData.mock()
        vm.navigationStack.append(makeFolderFile())
        let folder = makeFolderFile(name: "Public Folder")
        let url = vm.publicURL(forFile: folder)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("archive"))
    }

    func testPublicURL_RecordFile_ContainsRecordInURL() {
        let vm = PublicArchiveViewModel()
        vm.currentArchive = ArchiveVOData.mock()
        vm.navigationStack.append(makeFolderFile())
        let record = makeRecordFile()
        let url = vm.publicURL(forFile: record)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("record"))
    }

    // MARK: - VSP-1811: V1 getPublicRoot → V2 /children handoff
    // Stela's /archives is scoped to callerMembershipRole, so a FOREIGN archive is never
    // listed and the V2 section-root resolver can't bootstrap this screen. V1 getPublicRoot
    // stays as the bootstrap; when the flag is on, onGetRootSuccess seeds the public root as
    // the V2 navigation target so the listing itself is served by /folders/{id}/children.

    /// Mirrors the live staging `POST /folder/getPublicRoot` payload for a foreign public
    /// archive (verified 2026-07-28 against 00js-0000). `folderId` is parameterized so the
    /// `folderId > 0` gate in navigateMin can be exercised.
    private func decodeGetRoot(_ json: String) throws -> GetRootResponse {
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder().decode(GetRootResponse.self, from: data)
    }

    private func makeGetRootResponse(folderId: String = "42618") throws -> GetRootResponse {
        return try decodeGetRoot("""
        { "Results": [ { "data": [ { "FolderVO": {
            \(folderId.isEmpty ? "" : "\"folderId\": \(folderId),")
            "folder_linkId": 107086,
            "archiveNbr": "00js-0009",
            "archiveId": 1694,
            "displayName": "Public",
            "type": "type.folder.root.public"
        } } ] } ], "isSuccessful": true }
        """)
    }

    /// Captures whether the V2 children seam fired, and for which folder id. The V1 leg is
    /// stubbed too (see `StubV1GalleryViewModel`) so a test that deliberately drives the
    /// failsafe observes it directly instead of issuing a real POST /folder/navigateMin.
    private func makeGalleryVM(outcome: FilesViewModel.ChildrenFetchOutcome = .committed)
    -> (StubV1GalleryViewModel, () -> String?) {
        let vm = StubV1GalleryViewModel()
        var requestedFolderId: String?
        vm.childrenFetchV2Request = { folderId, completion in
            requestedFolderId = folderId
            completion(outcome)
        }
        return (vm, { requestedFolderId })
    }

    func testGetRootFixture_CarriesFolderId() throws {
        // Guards the fixture itself: if the V1 payload ever stops carrying folderId, the
        // handoff below silently degrades to V1 and the tests would still "pass".
        let folderVO = try XCTUnwrap(makeGetRootResponse().results?.first?.data?.first?.folderVO)
        XCTAssertEqual(folderVO.folderID, 42618)
        XCTAssertEqual(FileModel(model: folderVO).folderId, 42618,
                       "FileModel must carry the V1 folderId through, or navigateMin's gate rejects the target")
    }

    func testOnGetRootSuccess_FlagOn_HandsPublicRootToV2Children() throws {
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }

        let (vm, requestedFolderId) = makeGalleryVM(outcome: .committed)

        var status: RequestStatus?
        vm.onGetRootSuccess(try makeGetRootResponse()) { status = $0 }

        XCTAssertEqual(requestedFolderId(), "42618", "the V1 public root must hand off to V2 /children")
        XCTAssertEqual(status, .success)
        XCTAssertEqual(vm.navigationStack.last?.folderId, 42618, "the root must be on the stack")
        XCTAssertTrue(vm.currentFolderIsRoot, "one entry deep is root for this screen")
    }

    func testOnGetRootSuccess_FlagOff_NeverTouchesV2() throws {
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = false
        defer { FeatureFlags.useStelaNavigation = prevFlag }

        let (vm, requestedFolderId) = makeGalleryVM()
        vm.onGetRootSuccess(try makeGetRootResponse()) { _ in }

        XCTAssertNil(requestedFolderId(), "with the flag off the public root must list via V1")
        XCTAssertEqual(vm.v1NavigateMinCallCount, 1, "the flag-off path must go through the V1 leg exactly once")
    }

    func testOnGetRootSuccess_PublicRootWithoutFolderId_FallsThroughToV1() throws {
        // The V1 payload is all-optional. A root with no folderId maps to folderId == -1,
        // which navigateMin's `target.folderId > 0` gate must reject rather than issuing
        // GET /folders/-1/children. Seeding can only ever ADD a V2 attempt, never break V1.
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }

        let (vm, requestedFolderId) = makeGalleryVM()
        vm.onGetRootSuccess(try makeGetRootResponse(folderId: "")) { _ in }

        XCTAssertNil(requestedFolderId(), "an id-less root must not reach the V2 endpoint")
        XCTAssertEqual(vm.v1NavigateMinCallCount, 1, "an id-less root must fall through to the V1 leg")
    }

    func testOnGetRootSuccess_MalformedResponse_ErrorsWithoutNavigating() throws {
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }

        let (vm, requestedFolderId) = makeGalleryVM()
        let empty = try decodeGetRoot(#"{"Results":[],"isSuccessful":true}"#)

        var status: RequestStatus?
        vm.onGetRootSuccess(empty) { status = $0 }

        XCTAssertNil(requestedFolderId())
        XCTAssertTrue(vm.navigationStack.isEmpty)
        guard case .error = status else {
            return XCTFail("a rootless payload must surface an error, not a silent success")
        }
    }

    func testGetRoot_NoArchive_ErrorsInsteadOfCrashing() {
        // `currentArchive` comes from the host VC's implicitly-unwrapped `archiveData`, and
        // `archiveNbr` is optional on the VO. Both used to be force-unwrapped, so a nil
        // archive crashed the public browser instead of surfacing the error the rest of
        // getRoot's failure branches already report. The guard returns BEFORE the request,
        // so this asserts synchronously without touching the network.
        let vm = PublicArchiveViewModel()
        XCTAssertNil(vm.currentArchive, "precondition: no archive assigned")

        var status: RequestStatus?
        vm.getRoot(then: { status = $0 })

        guard case .error = status else {
            return XCTFail("a missing archive must surface an error, not crash or silently succeed")
        }
        XCTAssertTrue(vm.navigationStack.isEmpty, "nothing may be navigated without an archive")
    }

    // MARK: - VSP-1811: V2 drill-in

    /// Folder built via the V2 decode path — the convenience `init(name:recordId:…)` can't
    /// set `folderId`, which is exactly what navigateMin's gate reads.
    private func makeV2Folder(folderId: Int) throws -> FileModel {
        let json = """
        { "items": [ { "folderId": "\(folderId)", "displayName": "Folder \(folderId)",
          "type": "private", "status": "ok", "folderLinkId": "11", "archiveNumber": "00js-0032" } ] }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: data)
        let child = try XCTUnwrap(response.items?.first)
        return FileModel(model: child, permissions: [.read], accessRole: .viewer)
    }

    func testNavigateV2_DrillIn_CommittedAppendsAndLeavesRoot() throws {
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }

        let (vm, requestedFolderId) = makeGalleryVM(outcome: .committed)
        vm.navigationStack.append(try makeV2Folder(folderId: 42618))   // already at the public root
        vm.v2NavigationTarget = try makeV2Folder(folderId: 42668)

        var status: RequestStatus?
        vm.navigateMin(params: ("00js-0032", 11, nil), backNavigation: false) { status = $0 }

        XCTAssertEqual(requestedFolderId(), "42668")
        XCTAssertEqual(status, .success)
        XCTAssertEqual(vm.navigationStack.map { $0.folderId }, [42618, 42668])
        XCTAssertFalse(vm.currentFolderIsRoot, "two deep is no longer the root")
    }

    func testNavigateV2_DrillIn_FailedFallsBackToV1WithoutNavigating() throws {
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }

        let (vm, requestedFolderId) = makeGalleryVM(outcome: .failed(message: "boom"))
        vm.v2NavigationTarget = try makeV2Folder(folderId: 42668)

        vm.navigateMin(params: ("00js-0032", 11, nil), backNavigation: false) { _ in }

        XCTAssertEqual(requestedFolderId(), "42668", "V2 was attempted")
        XCTAssertTrue(vm.navigationStack.isEmpty, "a failed V2 fetch must not commit navigation")
        XCTAssertEqual(vm.v1NavigateMinCallCount, 1, "failure must reach the V1 failsafe exactly once")
        XCTAssertEqual(vm.v1NavigateMinBackNavigation, [false], "the failsafe must preserve the forward direction")
    }
}

// MARK: - PublicArchiveFileViewController (VSP-1811)
// Lives in this file rather than its own because adding a test FILE needs a project-file
// change in Xcode; move it out when convenient. Mirrors the SharesViewControllerTests /
// MainViewControllerTests pattern: instantiate the VC directly and wire the outlets by hand.

@MainActor
final class PublicArchiveFileViewControllerTests: XCTestCase {

    private func makeController(width: CGFloat = 402, height: CGFloat = 874)
    -> (PublicArchiveFileViewController, UICollectionView) {
        let vc = PublicArchiveFileViewController()
        // V1 leg stubbed — a flag-off tap would otherwise POST /folder/navigateMin for real.
        vc.viewModel = StubV1GalleryViewModel()

        let collectionView = UICollectionView(
            frame: CGRect(x: 0, y: 0, width: width, height: height),
            collectionViewLayout: UICollectionViewFlowLayout()
        )
        // Same layout configuration setupCollectionView() installs: the 6pt side gutters live
        // on the LAYOUT, and sizeForItemAt reads them back off it.
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.minimumInteritemSpacing = 6
            flowLayout.minimumLineSpacing = 0
            flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        }
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)

        // Keep the weak outlets alive on a retained root view.
        let rootView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        let directoryLabel = UILabel()
        let backButton = UIButton(type: .system)
        let linkButton = UIButton(type: .system)
        [directoryLabel, backButton, linkButton, collectionView].forEach { rootView.addSubview($0) }

        vc.view = rootView
        vc.collectionView = collectionView
        vc.directoryLabel = directoryLabel
        vc.backButton = backButton
        vc.linkButton = linkButton

        return (vc, collectionView)
    }

    private func makeV2Folder(folderId: Int) throws -> FileModel {
        // "public" is what the gallery's own children really carry (verified against staging),
        // unlike the "private" the other screens see.
        let json = """
        { "items": [ { "folderId": "\(folderId)", "displayName": "Folder \(folderId)",
          "type": "public", "status": "ok", "folderLinkId": "107367", "archiveNumber": "00js-0032" } ] }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: data)
        let child = try XCTUnwrap(response.items?.first)
        return FileModel(model: child, permissions: [.read], accessRole: .viewer)
    }

    private func size(of vc: PublicArchiveFileViewController, _ collectionView: UICollectionView) -> CGSize {
        return vc.collectionView(
            collectionView,
            layout: collectionView.collectionViewLayout,
            sizeForItemAt: IndexPath(row: 0, section: 0)
        )
    }

    // MARK: - Grid geometry

    func testSizeForItem_TwoUpGridFitsWithinTheCollectionViewWidth() {
        // The invariant that matters: two cells plus both gutters plus the inter-item gap
        // must never exceed the available width, or the flow layout drops to one column.
        for width in [320, 375, 390, 393, 402, 414, 428, 430, 440].map(CGFloat.init) {
            let (vc, collectionView) = makeController(width: width)
            let itemSize = size(of: vc, collectionView)

            XCTAssertLessThanOrEqual(itemSize.width * 2 + 6 + 6 + 6, width,
                                     "two-up grid must fit inside \(width)pt")
            XCTAssertEqual(itemSize.width, ((width - 18) / 2).rounded(.down),
                           "width must derive from the collection view, not UIScreen (at \(width)pt)")
            XCTAssertEqual(itemSize.height, itemSize.width + 39,
                           "height must stay width + 39 — the old (W/2 + 30) minus (W/2 - 9)")
        }
    }

    func testSizeForItem_NarrowerCollectionViewShrinksTheCell() {
        // The actual regression the rewrite fixes: sizing off UIScreen ignored the real
        // container, so a narrower collection view overflowed instead of shrinking.
        let (wideVC, wideCollectionView) = makeController(width: 402)
        let (narrowVC, narrowCollectionView) = makeController(width: 300)

        let wide = size(of: wideVC, wideCollectionView)
        let narrow = size(of: narrowVC, narrowCollectionView)

        XCTAssertLessThan(narrow.width, wide.width, "a narrower container must produce narrower cells")
        XCTAssertLessThanOrEqual(narrow.width * 2 + 18, 300)
    }

    func testSizeForItem_ZeroWidthCollectionViewStaysPositive() {
        // First layout pass can run before bounds resolve; a zero/negative size makes
        // UICollectionViewFlowLayout throw.
        let (vc, collectionView) = makeController(width: 0, height: 0)
        let itemSize = size(of: vc, collectionView)

        XCTAssertGreaterThan(itemSize.width, 0)
        XCTAssertGreaterThan(itemSize.height, 0)
    }

    // MARK: - V2 drill-in seeding (the ticket's deliverable)

    func testDidSelectFolder_FlagOn_SeedsTargetAndListsViaV2Children() throws {
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = true
        defer { FeatureFlags.useStelaNavigation = prevFlag }

        let (vc, collectionView) = makeController()
        let vm = try XCTUnwrap(vc.viewModel)

        var requestedFolderId: String?
        vm.childrenFetchV2Request = { folderId, completion in
            requestedFolderId = folderId
            completion(.committed)
        }

        let folder = try makeV2Folder(folderId: 42668)
        vm.viewModels = [folder]

        vc.collectionView(collectionView, didSelectItemAt: IndexPath(row: 0, section: 0))

        XCTAssertEqual(requestedFolderId, "42668",
                       "tapping a gallery folder must drill in through /folders/{id}/children")
        XCTAssertEqual(vm.navigationStack.map { $0.folderId }, [42668])
        XCTAssertEqual(vc.directoryLabel.text, folder.name)
        XCTAssertFalse(vc.backButton.isHidden, "entering a folder must reveal the back button")
        XCTAssertNil(vm.v2NavigationTarget, "the forward target is one-shot and must be consumed")
    }

    func testDidSelectFolder_FlagOff_NeverReachesV2() throws {
        let prevFlag = FeatureFlags.useStelaNavigation
        FeatureFlags.useStelaNavigation = false
        defer { FeatureFlags.useStelaNavigation = prevFlag }

        let (vc, collectionView) = makeController()
        let vm = try XCTUnwrap(vc.viewModel as? StubV1GalleryViewModel)

        var didReachV2 = false
        vm.childrenFetchV2Request = { _, completion in
            didReachV2 = true
            completion(.committed)
        }

        vm.viewModels = [try makeV2Folder(folderId: 42668)]
        vc.collectionView(collectionView, didSelectItemAt: IndexPath(row: 0, section: 0))

        XCTAssertFalse(didReachV2, "with the flag off the gallery must stay on the V1 two-step path")
        XCTAssertEqual(vm.v1NavigateMinCallCount, 1, "the tap must still navigate, via the V1 leg")
    }

    // NOTE: the record branch of didSelectItemAt is deliberately NOT tested here — it calls
    // presentFileDetails, which stands up the whole preview stack and fires a real record
    // fetch. Covered at the view-model level instead (FilePreviewViewModelTests).
}
