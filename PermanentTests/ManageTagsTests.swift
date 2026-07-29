//
//  ManageTagsTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 31.01.2023.
//
import XCTest
import KeychainSwift
@testable import Permanent


class ManageTagsTests: XCTestCase {
    var sut: ManageTagsViewModel!

    /// Captured so tearDown can put the process-wide session back. createMockSession() below
    /// installs a session whose account is AccountVOData.mock() ("Mock User"); leaving it behind
    /// leaked into unrelated tests — it is what made
    /// OnboardingContainerViewModelTests.testInit_NilCredentials_DefaultState see "Mock User"
    /// instead of "". Previously masked by the suite's live-network 401s nulling the session.
    private var previousSession: PermSession?

    override func setUp() {
        super.setUp()
        previousSession = AuthenticationManager.shared.session

        let tagsRemoteMockDataSource = TagsRemoteMockDataSource()
        let tagsManagementRepository = TagsRepository(remoteDataSource: tagsRemoteMockDataSource)
        sut = ManageTagsViewModel(tagsRepository: tagsManagementRepository)
        createMockSession()
    }
    
    override func tearDown() {
        sut = nil
        AuthenticationManager.shared.session = previousSession
        super.tearDown()
    }

    func testRefreshTags() {
        expectation(forNotification: ManageTagsViewModel.didUpdateTagsNotification, object: sut) { notification in
            return true
        }
        sut.refreshTags()

        waitForExpectations(timeout: 5)
        XCTAssertGreaterThan(sut.tags.count, 0, "Tags should be populated after refresh")
    }

    func testDeleteTag() {
        var temporarySut: ManageTagsViewModel!

        let tagsRemoteMockDataSource = TagsRemoteMockDataSource()
        let tagsManagementRepository = TagsRepository(remoteDataSource: tagsRemoteMockDataSource)
        temporarySut = ManageTagsViewModel(tagsRepository: tagsManagementRepository)

        let tag = TagVOData(name: "test", status: nil, tagId: 2, type: nil, createdDT: nil, updatedDT: nil)
        let tagVO = TagVO(tagVO: tag)
        temporarySut.tags.append(tagVO)
        temporarySut.sortedTags.append(tagVO)

        let deleteExpectation = expectation(description: "Delete tag callback")
        temporarySut.deleteTag(index: 0) { error in
            XCTAssertNil(tagsRemoteMockDataSource.deleteTagError)
            XCTAssertEqual(temporarySut.tags.count, 0)
            XCTAssertEqual(temporarySut.sortedTags.count, 0)
            deleteExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testSearchTags() {
        let firstTag = TagVOData(name: "test", status: nil, tagId: 2, type: nil, createdDT: nil, updatedDT: nil)
        let secondTag = TagVOData(name: "sample", status: nil, tagId: 3, type: nil, createdDT: nil, updatedDT: nil)
        let firstTagVO = TagVO(tagVO: firstTag)
        let secondTagVO = TagVO(tagVO: secondTag)
        sut.tags.append(firstTagVO)
        sut.tags.append(secondTagVO)
        sut.sortedTags = sut.tags
        sut.searchTags(withText: "test")
        XCTAssertEqual(sut.sortedTags.count, 1)
        sut.searchTags(withText: "")
        XCTAssertEqual(sut.sortedTags.count, 2)
    }

    func testIsLoading() {
        var wasLoading = false
        expectation(forNotification: ManageTagsViewModel.isLoadingNotification, object: sut) { notification in
            if self.sut.isLoading {
                wasLoading = true
            }
            return true
        }
        sut.refreshTags()

        waitForExpectations(timeout: 5)
        XCTAssertTrue(wasLoading, "isLoading should have been true at some point during refresh")
    }

    func testIsTagNameValid() {
        let tag = TagVOData(name: "test", status: nil, tagId: 2, type: nil, createdDT: nil, updatedDT: nil)
        let tagVO = TagVO(tagVO: tag)
        sut.tags.append(tagVO)
        sut.sortedTags.append(tagVO)
        XCTAssertFalse(sut.isNewTagNameValid(withText: "test"))
        XCTAssertFalse(sut.isNewTagNameValid(withText: ""))
        XCTAssertFalse(sut.isNewTagNameValid(withText: nil))
        XCTAssertTrue(sut.isNewTagNameValid(withText: "test 1"))
        XCTAssertTrue(sut.isNewTagNameValid(withText: "test 2"))
    }
    
    func testAddTag() {
        var temporarySut: ManageTagsViewModel!

        let tagsRemoteMockDataSource = TagsRemoteMockDataSource()
        let tagsManagementRepository = TagsRepository(remoteDataSource: tagsRemoteMockDataSource)
        temporarySut = ManageTagsViewModel(tagsRepository: tagsManagementRepository)

        expectation(forNotification: ManageTagsViewModel.showBannerNotification, object: temporarySut) { notification in
            return true
        }

        let addExpectation = expectation(description: "Add tag callback")
        temporarySut.addTagToArchive(withName: "test") { error in
            XCTAssertNil(error)
            XCTAssertEqual(temporarySut.tags.count, 1)
            XCTAssertEqual(temporarySut.sortedTags.count, 1)
            addExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testAddTagNil() {
        var temporarySut: ManageTagsViewModel!

        let tagsRemoteMockDataSource = TagsRemoteMockDataSource()
        let tagsManagementRepository = TagsRepository(remoteDataSource: tagsRemoteMockDataSource)
        temporarySut = ManageTagsViewModel(tagsRepository: tagsManagementRepository)

        let nilExpectation = expectation(description: "Add nil tag callback")
        temporarySut.addTagToArchive(withName: nil) { error in
            XCTAssertNotNil(error)
            nilExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testUpdateTag() {
        var temporarySut: ManageTagsViewModel!

        let tagsRemoteMockDataSource = TagsRemoteMockDataSource()
        let tagsManagementRepository = TagsRepository(remoteDataSource: tagsRemoteMockDataSource)
        temporarySut = ManageTagsViewModel(tagsRepository: tagsManagementRepository)

        let tag = TagVOData(name: "test", status: nil, tagId: 2, type: nil, createdDT: nil, updatedDT: nil)
        let tagVO = TagVO(tagVO: tag)
        temporarySut.tags.append(tagVO)
        temporarySut.sortedTags.append(tagVO)

        expectation(forNotification: ManageTagsViewModel.showBannerNotification, object: temporarySut) { notification in
            return true
        }

        let updateExpectation = expectation(description: "Update tag callback")
        temporarySut.updateTagName(newTagName: "test 1", index: 0) { error in
            XCTAssertNil(error)
            updateExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testUpdateTagNil() {
        var temporarySut: ManageTagsViewModel!

        let tagsRemoteMockDataSource = TagsRemoteMockDataSource()
        let tagsManagementRepository = TagsRepository(remoteDataSource: tagsRemoteMockDataSource)
        temporarySut = ManageTagsViewModel(tagsRepository: tagsManagementRepository)

        let tag = TagVOData(name: "test", status: nil, tagId: 2, type: nil, createdDT: nil, updatedDT: nil)
        let tagVO = TagVO(tagVO: tag)
        temporarySut.tags.append(tagVO)
        temporarySut.sortedTags.append(tagVO)

        let nilUpdateExpectation = expectation(description: "Update nil tag callback")
        temporarySut.updateTagName(newTagName: nil, index: 0) { error in
            XCTAssertNotNil(error)
            nilUpdateExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testGetTagName() {
        var temporarySut: ManageTagsViewModel!

        let tagsRemoteMockDataSource = TagsRemoteMockDataSource()
        let tagsManagementRepository = TagsRepository(remoteDataSource: tagsRemoteMockDataSource)
        temporarySut = ManageTagsViewModel(tagsRepository: tagsManagementRepository)

        let tag = TagVOData(name: "test", status: nil, tagId: 2, type: nil, createdDT: nil, updatedDT: nil)
        let tagVO = TagVO(tagVO: tag)
        temporarySut.tags.append(tagVO)
        temporarySut.sortedTags.append(tagVO)

        XCTAssertEqual(temporarySut.getTagNameFromIndex(index: 0), "test")
    }
    
    func createMockSession() {
        let session = PermSession(token: "test_token")
        session.selectedArchive = ArchiveVOData.mock()
        session.account = AccountVOData.mock()

        AuthenticationManager.shared.session = session
    }
}
