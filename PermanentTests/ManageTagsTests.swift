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

    override func setUp() {
        super.setUp()

        let tagsRemoteMockDataSource = TagsRemoteMockDataSource()
        let tagsManagementRepository = TagsRepository(remoteDataSource: tagsRemoteMockDataSource)
        sut = ManageTagsViewModel(tagsRepository: tagsManagementRepository)
        createMockSession()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testRefreshTags() {
        expectation(forNotification: ManageTagsViewModel.didUpdateTagsNotification, object: sut) { notification in
            XCTAssert(self.sut.tags.count > 0)
            return true
        }
        sut.refreshTags()
        
        waitForExpectations(timeout: 5)
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
        temporarySut.deleteTag(index: 0) { error in
            XCTAssertNil(tagsRemoteMockDataSource.deleteTagError)
            XCTAssert(temporarySut.tags.count == 0)
            XCTAssert(temporarySut.sortedTags.count == 0)
        }
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
        XCTAssert(self.sut.sortedTags.count == 1)
        sut.searchTags(withText: "")
        XCTAssert(self.sut.sortedTags.count == 2)
    }

    func testIsLoading() {
        expectation(forNotification: ManageTagsViewModel.isLoadingNotification, object: sut) { notification in
            if self.sut.isLoading {
                XCTAssert(true)
            }
            return true
        }
        sut.refreshTags()
        
        waitForExpectations(timeout: 5)
    }

    func testIsTagNameValid() {
        let tag = TagVOData(name: "test", status: nil, tagId: 2, type: nil, createdDT: nil, updatedDT: nil)
        let tagVO = TagVO(tagVO: tag)
        sut.tags.append(tagVO)
        sut.sortedTags.append(tagVO)
        XCTAssertFalse(sut.isNewTagNameValid(withText: "test"))
        XCTAssertFalse(sut.isNewTagNameValid(withText: ""))
        XCTAssertFalse(sut.isNewTagNameValid(withText: nil))
        XCTAssert(sut.isNewTagNameValid(withText: "test 1"))
        XCTAssert(sut.isNewTagNameValid(withText: "test 2"))
    }
    
    func testAddTag() {
        var temporarySut: ManageTagsViewModel!

        let tagsRemoteMockDataSource = TagsRemoteMockDataSource()
        let tagsManagementRepository = TagsRepository(remoteDataSource: tagsRemoteMockDataSource)
        temporarySut = ManageTagsViewModel(tagsRepository: tagsManagementRepository)

        expectation(forNotification: ManageTagsViewModel.showBannerNotification, object: temporarySut) { notification in
            return true
        }

        temporarySut.addTagToArchive(withName: "test") { error in
            XCTAssertNil(error)
            XCTAssert(temporarySut.tags.count == 1)
            XCTAssert(temporarySut.sortedTags.count == 1)
        }

        waitForExpectations(timeout: 5)
    }

    func testAddTagNil() {
        var temporarySut: ManageTagsViewModel!

        let tagsRemoteMockDataSource = TagsRemoteMockDataSource()
        let tagsManagementRepository = TagsRepository(remoteDataSource: tagsRemoteMockDataSource)
        temporarySut = ManageTagsViewModel(tagsRepository: tagsManagementRepository)

        temporarySut.addTagToArchive(withName: nil) { error in
            XCTAssertNotNil(error)
        }
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

        temporarySut.updateTagName(newTagName: "test 1", index: 0) { error in
            XCTAssertNil(error)
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

        temporarySut.updateTagName(newTagName: nil, index: 0) { error in
            XCTAssertNotNil(error)
        }
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
