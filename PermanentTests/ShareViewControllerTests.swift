//
//  ShareViewControllerTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 13.03.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class ShareViewControllerTests: XCTestCase {

    func testViewDidLoadSetsInitialStateAndRequestsRetrieveLink() {
        let vc = makeController()
        var requestedOptions: [ShareLinkOption] = []
        vc.shareLinkLoader = { option in
            requestedOptions.append(option)
        }

        vc.viewDidLoad()

        XCTAssertTrue(requestedOptions.contains(.retrieve))
        XCTAssertTrue(vc.linkOptionsStackView.isHidden)
        XCTAssertTrue(vc.linkOptionsView.delegate === vc)
        XCTAssertEqual(vc.filenameLabel.text, vc.sharedFile.name)
    }

    func testCreateLinkActionRequestsCreateLink() {
        let vc = makeController()
        var requestedOptions: [ShareLinkOption] = []
        vc.shareLinkLoader = { option in
            requestedOptions.append(option)
        }

        vc.createLinkAction(UIButton(type: .system))

        XCTAssertEqual(requestedOptions, [.create])
    }
    
    func testCloseButtonPressedDismissesController() {
        let vc = TestableShareViewController()
        vc.viewModel = makeViewModel()
        vc.closeButtonPressed(UIBarButtonItem())
        
        XCTAssertTrue(vc.didDismiss)
        XCTAssertEqual(vc.dismissAnimatedValue, true)
    }

    func testNumberOfRowsReturnsZeroWhenNoSharesLoaded() {
        let vc = makeController()
        XCTAssertEqual(vc.tableView(UITableView(), numberOfRowsInSection: 0), 0)
    }
    
    func testViewDidLoadWithoutLoaderCallsRetrieveAndFolderPathForFolderFile() {
        let vm = MockShareLinkViewModel(fileViewModel: makeFile(type: .privateFolder))
        vm.mockShareResult = makeShareResult()
        let vc = makeController(viewModel: vm)
        
        vc.viewDidLoad()
        
        XCTAssertTrue(vm.requestedOptions.contains(.retrieve))
        XCTAssertGreaterThanOrEqual(vm.getFolderCallCount, 1)
        XCTAssertEqual(vm.getRecordCallCount, 0)
    }
    
    func testViewDidLoadWithoutLoaderCallsRecordThenFolderFallbackForFile() {
        let vm = MockShareLinkViewModel(fileViewModel: makeFile(type: .miscellaneous))
        vm.mockShareResult = makeShareResult()
        vm.mockRecordResult = nil
        let vc = makeController(viewModel: vm)
        
        vc.viewDidLoad()
        
        XCTAssertTrue(vm.requestedOptions.contains(.retrieve))
        XCTAssertGreaterThanOrEqual(vm.getRecordCallCount, 1)
        XCTAssertGreaterThanOrEqual(vm.getFolderCallCount, 1)
    }
    
    func testViewDidLoadWithShareURLUpdatesLinkOptionsVisibility() {
        let vm = MockShareLinkViewModel(fileViewModel: makeFile(type: .privateFolder))
        vm.mockShareResult = makeShareResult(url: "https://example.com/link")
        let vc = makeController(viewModel: vm)
        let exp = expectation(description: "UI updated on main queue")
        
        vc.viewDidLoad()
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(vc.linkOptionsView.link, "https://example.com/link")
        XCTAssertTrue(vc.createLinkButton.isHidden)
        XCTAssertFalse(vc.linkOptionsStackView.isHidden)
    }
    
    func testCreateLinkActionWithoutInjectedLoaderCallsViewModelCreate() {
        let vm = MockShareLinkViewModel(fileViewModel: makeFile(type: .miscellaneous))
        let vc = makeController(viewModel: vm)
        
        vc.createLinkAction(UIButton(type: .system))
        
        XCTAssertEqual(vm.requestedOptions.last, .create)
    }
    
    func testCellForRowAtReturnsFallbackCellWhenArchiveCellNotRegistered() {
        let vm = MockShareLinkViewModel(fileViewModel: makeFile(type: .miscellaneous))
        vm.mockShareVOs = [makeShareVOData(id: 1)]
        let vc = makeController(viewModel: vm)
        let tableView = UITableView(frame: .zero)
        
        let cell = vc.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        
        XCTAssertFalse(cell is ArchiveTableViewCell)
    }
    
    func testNumberOfRowsUsesViewModelShareCount() {
        let vm = MockShareLinkViewModel(fileViewModel: makeFile(type: .miscellaneous))
        vm.mockShareVOs = [makeShareVOData(id: 1), makeShareVOData(id: 2)]
        let vc = makeController(viewModel: vm)
        
        XCTAssertEqual(vc.tableView(UITableView(), numberOfRowsInSection: 0), 2)
    }
    
    func testCopyLinkActionWithoutLinkDoesNotPresent() {
        let vm = MockShareLinkViewModel(fileViewModel: makeFile(type: .miscellaneous))
        let vc = TestableShareViewController()
        prepareController(vc, with: vm)
        vc.linkOptionsView.link = nil
        
        vc.copyLinkAction()
        
        XCTAssertFalse(vc.didPresent)
    }
    
    func testCopyLinkActionWithLinkAndAccountPresentsActivityController() {
        let vm = MockShareLinkViewModel(fileViewModel: makeFile(type: .miscellaneous))
        vm.mockAccountName = "Tester"
        let vc = TestableShareViewController()
        prepareController(vc, with: vm)
        vc.linkOptionsView.link = "https://example.com"
        
        vc.copyLinkAction()
        
        XCTAssertTrue(vc.didPresent)
        XCTAssertTrue(vc.lastPresented is UIActivityViewController)
    }
    
    func testManageLinkActionPresentsManageLinkControllerWhenAvailable() {
        let vm = MockShareLinkViewModel(fileViewModel: makeFile(type: .miscellaneous))
        let vc = TestableShareViewController()
        prepareController(vc, with: vm)
        
        vc.manageLinkAction()
        
        XCTAssertTrue(vc.didPresent)
    }

    private func makeController(viewModel: ShareLinkViewModel? = nil) -> ShareViewController {
        let vm = viewModel ?? makeViewModel()
        let vc = ShareViewController()
        prepareController(vc, with: vm)
        return vc
    }
    
    private func makeViewModel() -> ShareLinkViewModel {
        let file = makeFile(type: .miscellaneous)
        return ShareLinkViewModel(fileViewModel: file, shareManagementRepository: ShareManagementRepository(), downloader: nil)
    }
    
    private func makeFile(type: FileType) -> FileModel {
        FileModel(
            name: "Test file",
            recordId: 1,
            folderLinkId: 11,
            archiveNbr: "0",
            type: type.rawValue,
            permissions: [.read]
        )
    }
    
    private func makeShareResult(url: String? = "https://example.com") -> SharebyURLVOData {
        SharebyURLVOData(
            sharebyURLID: 123,
            status: nil,
            urlToken: nil,
            folderLinkID: nil,
            shareURL: url,
            uses: nil,
            maxUses: nil,
            autoApproveToggle: nil,
            previewToggle: nil,
            defaultAccessRole: nil,
            expiresDT: nil,
            byAccountID: nil,
            byArchiveID: nil,
            createdDT: nil,
            updatedDT: nil,
            accountVO: nil,
            folderData: nil,
            recordData: nil,
            archiveVO: nil,
            shareVO: nil
        )
    }
    
    private func makeShareVOData(id: Int) -> ShareVOData {
        ShareVOData(
            shareID: id,
            folderLinkID: 11,
            archiveID: 22,
            accessRole: AccessRole.viewer.apiValue,
            type: nil,
            status: nil,
            requestToken: nil,
            previewToggle: nil,
            folderVO: nil,
            recordVO: nil,
            archiveVO: nil,
            accountVO: nil,
            createdDT: nil,
            updatedDT: nil
        )
    }
    
    private func prepareController(_ vc: ShareViewController, with viewModel: ShareLinkViewModel) {
        vc.viewModel = viewModel
        vc.filenameLabel = UILabel()
        vc.createLinkButton = RoundedButton(frame: .zero)
        vc.linkOptionsView = LinkOptionsView(frame: .zero)
        vc.linkOptionsStackView = UIStackView()
        vc.titleLabel = UILabel()
        vc.descriptionLabel = UILabel()
        vc.tableView = UITableView(frame: .zero)
        vc.sharingWithLabel = UILabel()
    }
}

private final class TestableShareViewController: ShareViewController {
    var didDismiss = false
    var dismissAnimatedValue: Bool?
    var didPresent = false
    var lastPresented: UIViewController?
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        didDismiss = true
        dismissAnimatedValue = flag
        completion?()
    }
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        didPresent = true
        lastPresented = viewControllerToPresent
        completion?()
    }
}

private final class MockShareLinkViewModel: ShareLinkViewModel {
    var requestedOptions: [ShareLinkOption] = []
    var getRecordCallCount = 0
    var getFolderCallCount = 0
    var mockShareResult: SharebyURLVOData?
    var mockRecordResult: RecordVO?
    var mockFolderResult: FolderVO?
    var mockShareVOs: [ShareVOData] = []
    var mockAccountName: String?

    override var shareVOS: [ShareVOData]? {
        mockShareVOs
    }

    override func getShareLink(option: ShareLinkOption, then handler: @escaping ShareLinkResponse) {
        requestedOptions.append(option)
        handler(mockShareResult, nil)
    }
    
    override func getRecord(then handler: @escaping (RecordVO?) -> Void) {
        getRecordCallCount += 1
        handler(mockRecordResult)
    }
    
    override func getFolder(then handler: @escaping (FolderVO?) -> Void) {
        getFolderCallCount += 1
        handler(mockFolderResult)
    }
    
    override func getAccountName() -> String? {
        mockAccountName
    }
}
