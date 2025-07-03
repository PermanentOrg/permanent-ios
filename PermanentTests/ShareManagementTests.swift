//
// Created by Vlad Alexandru Rusu on 07.12.2022.
//

import XCTest
import KeychainSwift
@testable import Permanent

class ShareManagementTests: XCTestCase {
    var sut: ShareLinkViewModel!
    let token: String = "token"

    override func setUp() {
        super.setUp()

        let downloadManagerMock = DownloadManagerMock()
        let shareManagementMockDataSource = ShareManagementMockRemoteDataSource()
        shareManagementMockDataSource.sharebyURLVODataMock = sharebyURLVODataMock()
        shareManagementMockDataSource.shareVODataMock = shareVODataMock()
        let shareManagementRepository = ShareManagementRepository(remoteDataSource: shareManagementMockDataSource)
        let info = FolderInfo(folderId: 1, folderLinkId: 1)
        let url = URL(string: "https://google.com")!
        let model = FileModel(model: FileInfo(withURL: url, named: "Test", folder: info), permissions: [])
        sut = ShareLinkViewModel(fileViewModel: model, shareManagementRepository: shareManagementRepository, downloader: downloadManagerMock)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testGetShareLink() {
        let expectation = XCTestExpectation(description: "Get share link")
        sut.getShareLink(option: .create) { shareLink, error in
            XCTAssertNotNil(shareLink)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateLink(){
        let expectation = XCTestExpectation(description: "Update share link")
        sut.updateLink(model: ManageLinkData(previewToggle: 1, autoApproveToggle: 1, expiresDT: "", maxUses: 2,
                defaultAccessRole: AccessRole.viewer)) { shareLink, error in
            XCTAssertNotNil(shareLink)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testDeleteShareLink() {
        let expectation = XCTestExpectation(description: "Delete share link")
        sut.revokeLink { result in
            XCTAssertEqual(result, .success)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testApproveShareMinArchive() {
        let expectation = XCTestExpectation(description: "Approve share link")
        let vo = MinArchiveVO(name: "", thumbnail: "", shareStatus: "", shareId: 1, archiveID: 1, folderLinkID: 1, accessRole: "viewer")
        sut.approveButtonAction(minArchiveVO: vo) { result in
            XCTAssertEqual(result, .success)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testApproveShare() {
        let expectation = XCTestExpectation(description: "Approve share link")
        let vo = shareVODataMock()
        sut.approveButtonAction(shareVO: vo) { result in
            XCTAssertEqual(result, .success)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testDenyShareMinArchive() {
        let expectation = XCTestExpectation(description: "Deny share link")
        let vo = MinArchiveVO(name: "", thumbnail: "", shareStatus: "", shareId: 1, archiveID: 1, folderLinkID: 1, accessRole: "viewer")
        sut.denyButtonAction(minArchiveVO: vo) {
            status in
            XCTAssertEqual(status, .success)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testDenyShare() {
        let expectation = XCTestExpectation(description: "Deny share link")
        let vo = shareVODataMock()
        sut.denyButtonAction(shareVO: vo) {
            status in
            XCTAssertEqual(status, .success)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateLinkWithChangedField() {
        let expectation = XCTestExpectation(description: "Update share link with changed field")
        sut.updateLinkWithChangedField { data, error in
            XCTAssertNotNil(data)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testGetRecord() {
        let expectation = XCTestExpectation(description: "Get record")
        sut.getRecord { record in
            XCTAssertNotNil(record)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testGetFolder() {
        let expectation = XCTestExpectation(description: "Get folder")
        sut.getFolder { folder in
            XCTAssertNotNil(folder)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testShareVOs() {
        let expectation = XCTestExpectation(description: "Get share VOs")
        sut.getRecord { record in
            XCTAssertNotNil(record)

            self.sut.fileViewModel = FileModel(model: record!.recordVO!, permissions: [], accessRole: .owner)

            XCTAssert(self.sut.shareVOS?.count == 2)
            XCTAssert(self.sut.acceptedShareVOs.count == 1)
            XCTAssert(self.sut.pendingShareVOs.count == 1)

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testAccountName() {
        createMockSession()

        let accountName = sut.getAccountName()
        XCTAssert(accountName == "Test Account")
    }

    func shareVODataMock() -> ShareVOData {
        let json = "{\"Results\":[{\"data\":[{\"ShareVO\":{\"shareId\":1874,\"folder_linkId\":111145,\"archiveId\":1850,\"accessRole\":\"access.role.curator\",\"type\":\"type.share.record\",\"status\":\"status.generic.ok\",\"requestToken\":\"633442b551a7f216c8fba68206dba953b9a1ca31e1d4ccea2b74d6ed9ca87ab5\",\"previewToggle\":null,\"FolderVO\":null,\"RecordVO\":null,\"ArchiveVO\":null,\"AccountVO\":null,\"createdDT\":\"2022-11-25T16:51:50\",\"updatedDT\":\"2022-12-07T10:35:34\"}}],\"message\":[\"New share created or existing share updated\"],\"status\":true,\"resultDT\":\"2022-12-07T10:35:34\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":true,\"actionFailKeys\":[],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"csrf\":\"82c96e94642df8fdd3a2d6b5744c1286\",\"createdDT\":null,\"updatedDT\":null}"
        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        let model: APIResults<ShareVO> = try! decoder.decode(APIResults<ShareVO>.self, from: data)

        return model.results.first!.data!.first!.shareVO
    }

    func sharebyURLVODataMock() -> SharebyURLVOData {
        let json = "{\"Results\":[{\"data\":[{\"Shareby_urlVO\":{\"shareby_urlId\":919,\"folder_linkId\":111145,\"status\":\"status.generic.ok\",\"urlToken\":\"7e50e4fe99cc16892f3d0376df054b6ea56432e0ba9a563eebab08f70f34596b\",\"shareUrl\":\"https:\\/\\/staging.permanent.org\\/share\\/7e50e4fe99cc16892f3d0376df054b6ea56432e0ba9a563eebab08f70f34596b\",\"uses\":3,\"maxUses\":0,\"autoApproveToggle\":1,\"previewToggle\":1,\"defaultAccessRole\":\"access.role.curator\",\"expiresDT\":null,\"byAccountId\":1648,\"byArchiveId\":1858,\"createdDT\":\"2022-11-25T16:51:33\",\"updatedDT\":\"2022-11-30T12:40:19\",\"FolderVO\":null,\"RecordVO\":null,\"ArchiveVO\":null,\"AccountVO\":null,\"ShareVO\":null}}],\"message\":[\"Link exists\"],\"status\":true,\"resultDT\":\"2022-12-07T10:32:42\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":true,\"actionFailKeys\":[],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"csrf\":\"82c96e94642df8fdd3a2d6b5744c1286\",\"createdDT\":null,\"updatedDT\":null}"
        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        let model: APIResults<SharebyURLVO> = try! decoder.decode(APIResults<SharebyURLVO>.self, from: data)

        return model.results.first!.data!.first!.shareByURLVO!
    }

    func createMockSession() {
        let accountVO = AccountVOData(accountID: 1000, primaryEmail: "email@email.com", fullName: "Test Account", address: "Street", address2: nil, country: nil, city: nil, state: nil, zip: nil, primaryPhone: nil, level: nil, apiToken: nil, betaParticipant: nil, facebookAccountID: nil, googleAccountID: nil, status: nil, type: nil, emailStatus: nil, phoneStatus: nil, notificationPreferences: nil, agreed: nil, optIn: nil, emailArray: nil, inviteCode: nil, rememberMe: nil, keepLoggedIn: nil, accessRole: nil, spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil, changePrimaryEmail: nil, changePrimaryPhone: nil, createdDT: "2021-01-27T19:48:08", updatedDT: nil, hideChecklist: false)
        let session = PermSession(token: token)
        session.account = accountVO

        AuthenticationManager.shared.session = session
    }
}
