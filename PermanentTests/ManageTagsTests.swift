//
//  ManageTagsTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 31.01.2023.
//
import XCTest
import AppAuth
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
        let tag = TagVOData(name: "test", status: nil, tagId: 2, type: nil, createdDT: nil, updatedDT: nil)
        let tagVO = TagVO(tagVO: tag)
        sut.tags.append(tagVO)
        sut.sortedTags.append(tagVO)
        sut.deleteTag(index: 0) { error in
            XCTAssertNil(error)
            XCTAssert(self.sut.tags.count == 0)
            XCTAssert(self.sut.sortedTags.count == 0)
        }
    }

    func testSearchTags() {
        let tag = TagVOData(name: "test", status: nil, tagId: 2, type: nil, createdDT: nil, updatedDT: nil)
        let tagVO = TagVO(tagVO: tag)
        sut.tags.append(tagVO)
        sut.sortedTags.append(tagVO)
        sut.searchTags(withText: "test")
        XCTAssert(self.sut.sortedTags.count == 1)
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
    
    func createMockSession() {
        let archiveVO = ArchiveVOData(childFolderVOS: nil, folderSizeVOS: nil, recordVOS: nil, accessRole: nil, fullName: "test", spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil, relationType: nil, homeCity: nil, homeState: nil, homeCountry: nil, itemVOS: nil, birthDay: nil, company: nil, archiveVODescription: nil, archiveID: 1, publicDT: nil, archiveNbr: "777", view: nil, viewProperty: nil, archiveVOPublic: nil, vaultKey: nil, thumbArchiveNbr: nil, type: nil, thumbStatus: nil, imageRatio: nil, thumbURL200: nil, thumbURL500: nil, thumbURL1000: nil, thumbURL2000: nil, thumbDT: nil, createdDT: nil, updatedDT: nil, status: nil)
        let accountVO = AccountVOData(accountID: 1000, primaryEmail: "email@email.com", fullName: "Test Account", address: "Street", address2: nil, country: nil, city: nil, state: nil, zip: nil, primaryPhone: nil, level: nil, apiToken: nil, betaParticipant: nil, facebookAccountID: nil, googleAccountID: nil, status: nil, type: nil, emailStatus: nil, phoneStatus: nil, notificationPreferences: nil, agreed: nil, optIn: nil, emailArray: nil, inviteCode: nil, rememberMe: nil, keepLoggedIn: nil, accessRole: nil, spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil, changePrimaryEmail: nil, changePrimaryPhone: nil, createdDT: "2021-01-27T19:48:08", updatedDT: nil)
        let configuration = OIDServiceConfiguration(authorizationEndpoint: URL(string: "permanent.fusionAuth.org")!,
                tokenEndpoint: URL(string: "permanent.fusionAuth.org")!)
        let request = OIDAuthorizationRequest(
                configuration: configuration,
                clientId: "authServiceInfo.clientId",
                clientSecret: "authServiceInfo.clientSecret",
                scopes: ["offline_access"],
                redirectURL: URL(string: "org.permanent.permanentArchive://")!,
                responseType: OIDResponseTypeCode,
                additionalParameters: nil
        )
        let authState = OIDAuthState(authorizationResponse: OIDAuthorizationResponse(request: request, parameters: [:]))
        let session = PermSession(authState: authState)
        session.selectedArchive = archiveVO
        session.account = accountVO

        AuthenticationManager.shared.session = session
    }
}
