//
//  AccountEndpointTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class AccountEndpointTests: XCTestCase {

    private func dict(_ params: RequestParameters?) -> [String: Any]? {
        return params as? [String: Any]
    }

    // MARK: - Paths

    func testSignUp_Path() {
        let credentials: SignUpCredentials = (name: "Test", loginCredentials: (email: "test@test.com", password: "pass123"))
        let endpoint = AccountEndpoint.signUp(credentials: credentials)
        XCTAssertEqual(endpoint.path, "/account/post")
    }

    func testSignUpV2_Path() {
        let credentials: SignUpV2Credentials = (name: "Test", email: "test@test.com", password: "pass123", optIn: true, inviteCode: nil)
        let endpoint = AccountEndpoint.signUpV2(credentials: credentials)
        XCTAssertEqual(endpoint.path, "/account/post")
    }

    func testDelete_Path() {
        let endpoint = AccountEndpoint.delete(accountId: 1)
        XCTAssertEqual(endpoint.path, "/account/delete")
    }

    func testUpdateEmailAndPhone_Path() {
        let endpoint = AccountEndpoint.updateEmailAndPhone(accountId: 1, data: (email: "a@b.com", phone: "555"))
        XCTAssertEqual(endpoint.path, "/account/update")
    }

    func testUpdate_Path() {
        let endpoint = AccountEndpoint.update(accountVO: AccountVOData.mock())
        XCTAssertEqual(endpoint.path, "/account/update")
    }

    func testSendVerificationCodeSMS_Path() {
        let endpoint = AccountEndpoint.sendVerificationCodeSMS(accountId: 1, email: "a@b.com")
        XCTAssertEqual(endpoint.path, "/auth/resendTextCreatedAccount")
    }

    func testChangePassword_Path() {
        let endpoint = AccountEndpoint.changePassword(accountId: 1, passwordDetails: (password: "new", passwordVerify: "new", passwordOld: "old"))
        XCTAssertEqual(endpoint.path, "/account/changePassword")
    }

    func testGetUserData_Path() {
        let endpoint = AccountEndpoint.getUserData(accountId: 1)
        XCTAssertEqual(endpoint.path, "/account/get")
    }

    func testUpdateUserData_Path() {
        let updateData: UpdateUserData = (fullName: "Name", primaryEmail: nil, primaryPhone: nil, address: nil, address2: nil, city: nil, state: nil, zip: nil, country: nil)
        let endpoint = AccountEndpoint.updateUserData(accountId: 1, updateData: updateData)
        XCTAssertEqual(endpoint.path, "/account/update")
    }

    func testUpdateHideChecklist_Path() {
        let endpoint = AccountEndpoint.updateHideChecklist(accountId: AccountVOData.mock(), hideChecklist: true)
        XCTAssertEqual(endpoint.path, "/account/update")
    }

    func testUpdateShareRequest_Path() {
        let shareVO = ShareVOData(shareID: 1, folderLinkID: 2, archiveID: 3, accessRole: "access.role.owner", type: nil, status: "status.generic.ok", requestToken: nil, previewToggle: nil, folderVO: nil, recordVO: nil, archiveVO: nil, accountVO: nil, createdDT: nil, updatedDT: nil)
        let endpoint = AccountEndpoint.updateShareRequest(shareVO: shareVO)
        XCTAssertEqual(endpoint.path, "/share/upsert")
    }

    func testUpdateShareArchiveRequest_Path() {
        let archiveVO = MinArchiveVO(name: "Test", thumbnail: nil, shareStatus: "status.generic.ok", shareId: 10, archiveID: 20, folderLinkID: 30, accessRole: "access.role.viewer")
        let endpoint = AccountEndpoint.updateShareArchiveRequest(archiveVO: archiveVO)
        XCTAssertEqual(endpoint.path, "/share/upsert")
    }

    func testDeleteShareRequest_Path() {
        let endpoint = AccountEndpoint.deleteShareRequest(shareId: 1, folderLinkId: 2, archiveId: 3)
        XCTAssertEqual(endpoint.path, "/share/delete")
    }

    func testRedeemCode_Path() {
        let endpoint = AccountEndpoint.redeemCode(code: "PROMO123")
        XCTAssertEqual(endpoint.path, "/promo/entry")
    }

    func testGetSessionAccount_Path() {
        let endpoint = AccountEndpoint.getSessionAccount
        XCTAssertEqual(endpoint.path, "/account/getsessionaccount")
    }

    func testAddRemoveTags_Path() {
        let endpoint = AccountEndpoint.addRemoveTags(archiveType: "type:person", addGoalTags: nil, addWhyTags: nil, removeGoalTags: nil, removeWhyTags: nil)
        XCTAssertEqual(endpoint.path, "/account/tags")
    }

    // MARK: - Method

    func testMostEndpoints_UsePostMethod() {
        let endpoints: [AccountEndpoint] = [
            .signUp(credentials: (name: "N", loginCredentials: (email: "e@e.com", password: "p"))),
            .signUpV2(credentials: (name: "N", email: "e@e.com", password: "p", optIn: false, inviteCode: nil)),
            .delete(accountId: 1),
            .updateEmailAndPhone(accountId: 1, data: (email: "e@e.com", phone: "555")),
            .update(accountVO: AccountVOData.mock()),
            .sendVerificationCodeSMS(accountId: 1, email: "e@e.com"),
            .changePassword(accountId: 1, passwordDetails: (password: "p", passwordVerify: "p", passwordOld: "o")),
            .getUserData(accountId: 1),
            .updateUserData(accountId: 1, updateData: (fullName: nil, primaryEmail: nil, primaryPhone: nil, address: nil, address2: nil, city: nil, state: nil, zip: nil, country: nil)),
            .updateHideChecklist(accountId: AccountVOData.mock(), hideChecklist: false),
            .updateShareRequest(shareVO: ShareVOData(shareID: 1, folderLinkID: 2, archiveID: 3, accessRole: nil, type: nil, status: nil, requestToken: nil, previewToggle: nil, folderVO: nil, recordVO: nil, archiveVO: nil, accountVO: nil, createdDT: nil, updatedDT: nil)),
            .updateShareArchiveRequest(archiveVO: MinArchiveVO(name: "T", thumbnail: nil, shareStatus: "ok", shareId: 1, archiveID: 2, folderLinkID: 3, accessRole: nil)),
            .deleteShareRequest(shareId: 1, folderLinkId: 2, archiveId: 3),
            .redeemCode(code: "CODE"),
            .getSessionAccount
        ]

        for endpoint in endpoints {
            XCTAssertEqual(endpoint.method, .post, "Expected POST for \(endpoint)")
        }
    }

    func testAddRemoveTags_UsesPutMethod() {
        let endpoint = AccountEndpoint.addRemoveTags(archiveType: "type:person", addGoalTags: nil, addWhyTags: nil, removeGoalTags: nil, removeWhyTags: nil)
        XCTAssertEqual(endpoint.method, .put)
    }

    // MARK: - Request/Response Types

    func testRequestType_IsData() {
        let endpoint = AccountEndpoint.getSessionAccount
        XCTAssertEqual(endpoint.requestType, .data)
    }

    func testResponseType_IsJSON() {
        let endpoint = AccountEndpoint.getSessionAccount
        XCTAssertEqual(endpoint.responseType, .json)
    }

    // MARK: - Body Data

    func testBodyData_IsNilForAllCases() {
        let endpoints: [AccountEndpoint] = [
            .signUp(credentials: (name: "N", loginCredentials: (email: "e@e.com", password: "p"))),
            .delete(accountId: 1),
            .getSessionAccount,
            .addRemoveTags(archiveType: "type:person", addGoalTags: nil, addWhyTags: nil, removeGoalTags: nil, removeWhyTags: nil)
        ]

        for endpoint in endpoints {
            XCTAssertNil(endpoint.bodyData, "bodyData should be nil for \(endpoint)")
        }
    }

    // MARK: - Headers

    func testHeaders_PostEndpoint_ContainsContentType() {
        let endpoint = AccountEndpoint.getSessionAccount
        let headers = endpoint.headers
        XCTAssertEqual(headers?["content-type"], "application/json; charset=utf-8")
    }

    func testHeaders_SignUpV2_ContainsRequestVersion() {
        let credentials: SignUpV2Credentials = (name: "Test", email: "t@t.com", password: "pass", optIn: true, inviteCode: nil)
        let endpoint = AccountEndpoint.signUpV2(credentials: credentials)
        let headers = endpoint.headers
        XCTAssertEqual(headers?["Request-Version"], "2")
        XCTAssertEqual(headers?["content-type"], "application/json; charset=utf-8")
    }

    func testHeaders_NonSignUpV2Post_DoesNotContainRequestVersion() {
        let endpoint = AccountEndpoint.signUp(credentials: (name: "N", loginCredentials: (email: "e@e.com", password: "p")))
        let headers = endpoint.headers
        XCTAssertNil(headers?["Request-Version"])
    }

    func testHeaders_PutEndpoint_ContainsContentType() {
        let endpoint = AccountEndpoint.addRemoveTags(archiveType: "type:person", addGoalTags: nil, addWhyTags: nil, removeGoalTags: nil, removeWhyTags: nil)
        let headers = endpoint.headers
        XCTAssertEqual(headers?["content-type"], "application/json; charset=utf-8")
    }

    // MARK: - Progress Handler

    func testProgressHandler_IsNilForAllCases() {
        let endpoint = AccountEndpoint.delete(accountId: 1)
        XCTAssertNil(endpoint.progressHandler)
    }

    // MARK: - Custom URL

    func testCustomURL_AddRemoveTags_ContainsApiV2Path() {
        let endpoint = AccountEndpoint.addRemoveTags(archiveType: "type:person", addGoalTags: nil, addWhyTags: nil, removeGoalTags: nil, removeWhyTags: nil)
        XCTAssertNotNil(endpoint.customURL)
        XCTAssertTrue(endpoint.customURL!.contains("api/v2/account/tags"))
    }

    func testCustomURL_NonTagEndpoints_ReturnsNil() {
        let endpoints: [AccountEndpoint] = [
            .signUp(credentials: (name: "N", loginCredentials: (email: "e@e.com", password: "p"))),
            .delete(accountId: 1),
            .getSessionAccount,
            .redeemCode(code: "CODE"),
            .getUserData(accountId: 1)
        ]

        for endpoint in endpoints {
            XCTAssertNil(endpoint.customURL, "customURL should be nil for \(endpoint)")
        }
    }

    // MARK: - signUp Parameters

    func testSignUp_Parameters_ContainsAccountVO() {
        let credentials: SignUpCredentials = (name: "John Doe", loginCredentials: (email: "john@example.com", password: "secret123"))
        let endpoint = AccountEndpoint.signUp(credentials: credentials)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let accountVO = data?.first?["AccountVO"] as? [String: Any]

        XCTAssertEqual(accountVO?["primaryEmail"] as? String, "john@example.com")
        XCTAssertEqual(accountVO?["fullName"] as? String, "John Doe")
        XCTAssertEqual(accountVO?["agreed"] as? Bool, true)
        XCTAssertEqual(accountVO?["optIn"] as? Bool, false)
    }

    func testSignUp_Parameters_ContainsAccountPasswordVO() {
        let credentials: SignUpCredentials = (name: "Jane", loginCredentials: (email: "jane@test.com", password: "myPass"))
        let endpoint = AccountEndpoint.signUp(credentials: credentials)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let passwordVO = data?.first?["AccountPasswordVO"] as? [String: Any]

        XCTAssertEqual(passwordVO?["password"] as? String, "myPass")
        XCTAssertEqual(passwordVO?["passwordVerify"] as? String, "myPass")
    }

    func testSignUp_Parameters_ContainsSimpleVO() {
        let credentials: SignUpCredentials = (name: "Test", loginCredentials: (email: "t@t.com", password: "p"))
        let endpoint = AccountEndpoint.signUp(credentials: credentials)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let simpleVO = data?.first?["SimpleVO"] as? [String: Any]

        XCTAssertEqual(simpleVO?["key"] as? String, "createArchive")
        XCTAssertEqual(simpleVO?["value"] as? Bool, false)
    }

    // MARK: - signUpV2 Parameters

    func testSignUpV2_Parameters_ContainsRequiredFields() {
        let credentials: SignUpV2Credentials = (name: "Alice", email: "alice@test.com", password: "pass456", optIn: true, inviteCode: nil)
        let endpoint = AccountEndpoint.signUpV2(credentials: credentials)
        let params = dict(endpoint.parameters)

        XCTAssertEqual(params?["fullName"] as? String, "Alice")
        XCTAssertEqual(params?["primaryEmail"] as? String, "alice@test.com")
        XCTAssertEqual(params?["password"] as? String, "pass456")
        XCTAssertEqual(params?["passwordVerify"] as? String, "pass456")
        XCTAssertEqual(params?["optIn"] as? Bool, true)
        XCTAssertEqual(params?["agreed"] as? Bool, true)
        XCTAssertEqual(params?["createArchive"] as? Bool, false)
    }

    func testSignUpV2_Parameters_WithInviteCode() {
        let credentials: SignUpV2Credentials = (name: "Bob", email: "bob@test.com", password: "pass", optIn: false, inviteCode: "INVITE123")
        let endpoint = AccountEndpoint.signUpV2(credentials: credentials)
        let params = dict(endpoint.parameters)

        XCTAssertEqual(params?["inviteCode"] as? String, "INVITE123")
    }

    func testSignUpV2_Parameters_NilInviteCode_DoesNotContainKey() {
        let credentials: SignUpV2Credentials = (name: "Bob", email: "bob@test.com", password: "pass", optIn: false, inviteCode: nil)
        let endpoint = AccountEndpoint.signUpV2(credentials: credentials)
        let params = dict(endpoint.parameters)

        XCTAssertNil(params?["inviteCode"])
    }

    func testSignUpV2_Parameters_EmptyInviteCode_DoesNotContainKey() {
        let credentials: SignUpV2Credentials = (name: "Bob", email: "bob@test.com", password: "pass", optIn: false, inviteCode: "")
        let endpoint = AccountEndpoint.signUpV2(credentials: credentials)
        let params = dict(endpoint.parameters)

        XCTAssertNil(params?["inviteCode"])
    }

    // MARK: - delete Parameters

    func testDelete_Parameters_ContainsAccountId() {
        let endpoint = AccountEndpoint.delete(accountId: 42)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let accountVO = data?.first?["AccountVO"] as? [String: Any]

        XCTAssertEqual(accountVO?["accountId"] as? Int, 42)
    }

    // MARK: - updateEmailAndPhone Parameters

    func testUpdateEmailAndPhone_Parameters_ContainsAccountIdAndData() {
        let endpoint = AccountEndpoint.updateEmailAndPhone(accountId: 10, data: (email: "new@test.com", phone: "+1-555-1234"))
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let accountVO = data?.first?["AccountVO"] as? [String: Any]

        XCTAssertEqual(accountVO?["accountId"] as? Int, 10)
        XCTAssertEqual(accountVO?["primaryEmail"] as? String, "new@test.com")
        XCTAssertEqual(accountVO?["primaryPhone"] as? String, "+1-555-1234")
    }

    // MARK: - update Parameters

    func testUpdate_Parameters_ContainsAccountVOData() {
        let mockAccount = AccountVOData.mock()
        let endpoint = AccountEndpoint.update(accountVO: mockAccount)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let accountVO = data?.first?["AccountVO"] as? [String: Any]

        XCTAssertNotNil(accountVO)
        XCTAssertEqual(accountVO?["accountId"] as? Int, 1)
        XCTAssertEqual(accountVO?["primaryEmail"] as? String, "mock@example.com")
        XCTAssertEqual(accountVO?["fullName"] as? String, "Mock User")
    }

    // MARK: - sendVerificationCodeSMS Parameters

    func testSendVerificationCodeSMS_Parameters_ContainsAccountIdAndEmail() {
        let endpoint = AccountEndpoint.sendVerificationCodeSMS(accountId: 99, email: "verify@test.com")
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let accountVO = data?.first?["AccountVO"] as? [String: Any]

        XCTAssertEqual(accountVO?["accountId"] as? Int, 99)
        XCTAssertEqual(accountVO?["primaryEmail"] as? String, "verify@test.com")
    }

    // MARK: - changePassword Parameters

    func testChangePassword_Parameters_ContainsAccountVOAndPasswordVO() {
        let passwordDetails: ChangePasswordCredentials = (password: "newPass", passwordVerify: "newPass", passwordOld: "oldPass")
        let endpoint = AccountEndpoint.changePassword(accountId: 5, passwordDetails: passwordDetails)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let accountVO = data?.first?["AccountVO"] as? [String: Any]
        let passwordVO = data?.first?["AccountPasswordVO"] as? [String: Any]

        XCTAssertEqual(accountVO?["accountId"] as? Int, 5)
        XCTAssertEqual(passwordVO?["password"] as? String, "newPass")
        XCTAssertEqual(passwordVO?["passwordVerify"] as? String, "newPass")
        XCTAssertEqual(passwordVO?["passwordOld"] as? String, "oldPass")
    }

    // MARK: - getUserData Parameters

    func testGetUserData_Parameters_ContainsAccountId() {
        let endpoint = AccountEndpoint.getUserData(accountId: 77)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let accountVO = data?.first?["AccountVO"] as? [String: Any]

        XCTAssertEqual(accountVO?["accountId"] as? Int, 77)
    }

    // MARK: - updateUserData Parameters

    func testUpdateUserData_Parameters_ContainsAllFields() {
        let updateData: UpdateUserData = (fullName: "Updated Name", primaryEmail: "updated@test.com", primaryPhone: "+1-555-9999", address: "123 Main St", address2: "Suite 100", city: "Springfield", state: "IL", zip: "62701", country: "US")
        let endpoint = AccountEndpoint.updateUserData(accountId: 50, updateData: updateData)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let accountVO = data?.first?["AccountVO"] as? [String: Any]

        XCTAssertEqual(accountVO?["accountId"] as? Int, 50)
        XCTAssertEqual(accountVO?["fullName"] as? String, "Updated Name")
        XCTAssertEqual(accountVO?["primaryEmail"] as? String, "updated@test.com")
        XCTAssertEqual(accountVO?["primaryPhone"] as? String, "+1-555-9999")
        XCTAssertEqual(accountVO?["address"] as? String, "123 Main St")
        XCTAssertEqual(accountVO?["address2"] as? String, "Suite 100")
        XCTAssertEqual(accountVO?["city"] as? String, "Springfield")
        XCTAssertEqual(accountVO?["state"] as? String, "IL")
        XCTAssertEqual(accountVO?["zip"] as? String, "62701")
        XCTAssertEqual(accountVO?["country"] as? String, "US")
    }

    func testUpdateUserData_Parameters_WithNilFields() {
        let updateData: UpdateUserData = (fullName: nil, primaryEmail: nil, primaryPhone: nil, address: nil, address2: nil, city: nil, state: nil, zip: nil, country: nil)
        let endpoint = AccountEndpoint.updateUserData(accountId: 50, updateData: updateData)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let accountVO = data?.first?["AccountVO"] as? [String: Any]

        XCTAssertEqual(accountVO?["accountId"] as? Int, 50)
        // nil fields are still included as NSNull via `as Any` casting
        XCTAssertNotNil(accountVO)
    }

    // MARK: - updateHideChecklist Parameters

    func testUpdateHideChecklist_Parameters_ContainsHideChecklistTrue() {
        let mockAccount = AccountVOData.mock()
        let endpoint = AccountEndpoint.updateHideChecklist(accountId: mockAccount, hideChecklist: true)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let accountVO = data?.first?["AccountVO"] as? [String: Any]

        XCTAssertEqual(accountVO?["hideChecklist"] as? Bool, true)
        XCTAssertEqual(accountVO?["accountId"] as? Int, mockAccount.accountID)
    }

    func testUpdateHideChecklist_Parameters_ContainsHideChecklistFalse() {
        let mockAccount = AccountVOData.mock()
        let endpoint = AccountEndpoint.updateHideChecklist(accountId: mockAccount, hideChecklist: false)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let accountVO = data?.first?["AccountVO"] as? [String: Any]

        XCTAssertEqual(accountVO?["hideChecklist"] as? Bool, false)
    }

    func testUpdateHideChecklist_Parameters_ContainsAccountFields() {
        let mockAccount = AccountVOData.mock()
        let endpoint = AccountEndpoint.updateHideChecklist(accountId: mockAccount, hideChecklist: true)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let accountVO = data?.first?["AccountVO"] as? [String: Any]

        XCTAssertEqual(accountVO?["fullName"] as? String, mockAccount.fullName)
        XCTAssertEqual(accountVO?["primaryEmail"] as? String, mockAccount.primaryEmail)
        XCTAssertEqual(accountVO?["primaryPhone"] as? String, mockAccount.primaryPhone)
        XCTAssertEqual(accountVO?["address"] as? String, mockAccount.address)
        XCTAssertEqual(accountVO?["address2"] as? String, mockAccount.address2)
        XCTAssertEqual(accountVO?["city"] as? String, mockAccount.city)
        XCTAssertEqual(accountVO?["state"] as? String, mockAccount.state)
        XCTAssertEqual(accountVO?["zip"] as? String, mockAccount.zip)
        XCTAssertEqual(accountVO?["country"] as? String, mockAccount.country)
    }

    // MARK: - updateShareRequest Parameters

    func testUpdateShareRequest_Parameters_ContainsShareVO() {
        let shareVO = ShareVOData(shareID: 1, folderLinkID: 2, archiveID: 3, accessRole: "access.role.owner", type: nil, status: "status.generic.ok", requestToken: nil, previewToggle: nil, folderVO: nil, recordVO: nil, archiveVO: nil, accountVO: nil, createdDT: nil, updatedDT: nil)
        let endpoint = AccountEndpoint.updateShareRequest(shareVO: shareVO)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let shareDict = data?.first?["ShareVO"] as? [String: Any]

        XCTAssertNotNil(shareDict)
        XCTAssertEqual(shareDict?["shareId"] as? Int, 1)
        XCTAssertEqual(shareDict?["folder_linkId"] as? Int, 2)
        XCTAssertEqual(shareDict?["archiveId"] as? Int, 3)
        XCTAssertEqual(shareDict?["accessRole"] as? String, "access.role.owner")
        XCTAssertEqual(shareDict?["status"] as? String, "status.generic.ok")
    }

    // MARK: - updateShareArchiveRequest Parameters

    func testUpdateShareArchiveRequest_Parameters_ContainsShareVOFromMinArchive() {
        let archiveVO = MinArchiveVO(name: "Test", thumbnail: nil, shareStatus: "status.generic.ok", shareId: 10, archiveID: 20, folderLinkID: 30, accessRole: "access.role.viewer")
        let endpoint = AccountEndpoint.updateShareArchiveRequest(archiveVO: archiveVO)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let shareDict = data?.first?["ShareVO"] as? [String: Any]

        XCTAssertNotNil(shareDict)
        XCTAssertEqual(shareDict?["shareId"] as? Int, 10)
        XCTAssertEqual(shareDict?["archiveId"] as? Int, 20)
        XCTAssertEqual(shareDict?["folder_linkId"] as? Int, 30)
        XCTAssertEqual(shareDict?["accessRole"] as? String, "access.role.viewer")
        XCTAssertEqual(shareDict?["status"] as? String, "status.generic.ok")
    }

    // MARK: - deleteShareRequest Parameters

    func testDeleteShareRequest_Parameters_ContainsShareVO() {
        let endpoint = AccountEndpoint.deleteShareRequest(shareId: 100, folderLinkId: 200, archiveId: 300)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let shareVO = data?.first?["ShareVO"] as? [String: Any]

        XCTAssertEqual(shareVO?["shareId"] as? Int, 100)
        XCTAssertEqual(shareVO?["folder_linkId"] as? Int, 200)
        XCTAssertEqual(shareVO?["archiveId"] as? Int, 300)
    }

    // MARK: - redeemCode Parameters

    func testRedeemCode_Parameters_ContainsPromoVO() {
        let endpoint = AccountEndpoint.redeemCode(code: "PROMO2026")
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let promoVO = data?.first?["PromoVO"] as? [String: Any]

        XCTAssertEqual(promoVO?["code"] as? String, "PROMO2026")
    }

    // MARK: - getSessionAccount Parameters

    func testGetSessionAccount_Parameters_ContainsEmptyData() {
        let endpoint = AccountEndpoint.getSessionAccount
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]

        XCTAssertNotNil(data)
        XCTAssertEqual(data?.count, 1)
        XCTAssertTrue(data?.first?.isEmpty == true)
    }

    // MARK: - addRemoveTags Parameters

    func testAddRemoveTags_Parameters_ArchiveTypeInAddTags() {
        let endpoint = AccountEndpoint.addRemoveTags(archiveType: "type:person", addGoalTags: nil, addWhyTags: nil, removeGoalTags: nil, removeWhyTags: nil)
        let params = dict(endpoint.parameters)

        let addTags = params?["addTags"] as? [String]
        XCTAssertNotNil(addTags)
        XCTAssertEqual(addTags?.first, "type:person")
    }

    func testAddRemoveTags_Parameters_GoalTagsFormatted() {
        let endpoint = AccountEndpoint.addRemoveTags(archiveType: "type:person", addGoalTags: ["education", "career"], addWhyTags: nil, removeGoalTags: nil, removeWhyTags: nil)
        let params = dict(endpoint.parameters)

        let addTags = params?["addTags"] as? [String]
        XCTAssertTrue(addTags?.contains("goal:education") == true)
        XCTAssertTrue(addTags?.contains("goal:career") == true)
    }

    func testAddRemoveTags_Parameters_WhyTagsFormatted() {
        let endpoint = AccountEndpoint.addRemoveTags(archiveType: "type:person", addGoalTags: nil, addWhyTags: ["preserve", "share"], removeGoalTags: nil, removeWhyTags: nil)
        let params = dict(endpoint.parameters)

        let addTags = params?["addTags"] as? [String]
        XCTAssertTrue(addTags?.contains("why:preserve") == true)
        XCTAssertTrue(addTags?.contains("why:share") == true)
    }

    func testAddRemoveTags_Parameters_RemoveGoalTagsFormatted() {
        let endpoint = AccountEndpoint.addRemoveTags(archiveType: "type:person", addGoalTags: nil, addWhyTags: nil, removeGoalTags: ["oldGoal"], removeWhyTags: nil)
        let params = dict(endpoint.parameters)

        let removeTags = params?["removeTags"] as? [String]
        XCTAssertTrue(removeTags?.contains("goal:oldGoal") == true)
    }

    func testAddRemoveTags_Parameters_RemoveWhyTagsFormatted() {
        let endpoint = AccountEndpoint.addRemoveTags(archiveType: "type:person", addGoalTags: nil, addWhyTags: nil, removeGoalTags: nil, removeWhyTags: ["oldWhy"])
        let params = dict(endpoint.parameters)

        let removeTags = params?["removeTags"] as? [String]
        XCTAssertTrue(removeTags?.contains("why:oldWhy") == true)
    }

    func testAddRemoveTags_Parameters_NilArrays_EmptyRemoveTags() {
        let endpoint = AccountEndpoint.addRemoveTags(archiveType: "type:person", addGoalTags: nil, addWhyTags: nil, removeGoalTags: nil, removeWhyTags: nil)
        let params = dict(endpoint.parameters)

        let removeTags = params?["removeTags"] as? [String]
        XCTAssertNotNil(removeTags)
        XCTAssertTrue(removeTags?.isEmpty == true)
    }

    func testAddRemoveTags_Parameters_NilGoalAndWhyTags_OnlyArchiveTypeInAddTags() {
        let endpoint = AccountEndpoint.addRemoveTags(archiveType: "type:family", addGoalTags: nil, addWhyTags: nil, removeGoalTags: nil, removeWhyTags: nil)
        let params = dict(endpoint.parameters)

        let addTags = params?["addTags"] as? [String]
        XCTAssertEqual(addTags?.count, 1)
        XCTAssertEqual(addTags?.first, "type:family")
    }

    func testAddRemoveTags_Parameters_AllTagTypes_CombinedCorrectly() {
        let endpoint = AccountEndpoint.addRemoveTags(
            archiveType: "type:organization",
            addGoalTags: ["goal1"],
            addWhyTags: ["why1"],
            removeGoalTags: ["removeGoal1"],
            removeWhyTags: ["removeWhy1"]
        )
        let params = dict(endpoint.parameters)

        let addTags = params?["addTags"] as? [String]
        let removeTags = params?["removeTags"] as? [String]

        // addTags should contain: archiveType + goal tags + why tags
        XCTAssertEqual(addTags?.count, 3)
        XCTAssertEqual(addTags?[0], "type:organization")
        XCTAssertEqual(addTags?[1], "goal:goal1")
        XCTAssertEqual(addTags?[2], "why:why1")

        // removeTags should contain: remove goal tags + remove why tags
        XCTAssertEqual(removeTags?.count, 2)
        XCTAssertEqual(removeTags?[0], "goal:removeGoal1")
        XCTAssertEqual(removeTags?[1], "why:removeWhy1")
    }

    func testAddRemoveTags_Parameters_MultipleGoalAndWhyTags() {
        let endpoint = AccountEndpoint.addRemoveTags(
            archiveType: "type:person",
            addGoalTags: ["a", "b", "c"],
            addWhyTags: ["x", "y"],
            removeGoalTags: ["d"],
            removeWhyTags: ["z"]
        )
        let params = dict(endpoint.parameters)

        let addTags = params?["addTags"] as? [String]
        let removeTags = params?["removeTags"] as? [String]

        // 1 archiveType + 3 goals + 2 whys = 6
        XCTAssertEqual(addTags?.count, 6)
        // 1 remove goal + 1 remove why = 2
        XCTAssertEqual(removeTags?.count, 2)
    }

    // MARK: - Payload Structure Validation

    func testSignUp_PayloadStructure_HasRequestVOWithDataArray() {
        let credentials: SignUpCredentials = (name: "Test", loginCredentials: (email: "t@t.com", password: "p"))
        let endpoint = AccountEndpoint.signUp(credentials: credentials)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        XCTAssertNotNil(requestVO, "Top level should contain RequestVO")

        let data = requestVO?["data"] as? [[String: Any]]
        XCTAssertNotNil(data, "RequestVO should contain data array")
        XCTAssertEqual(data?.count, 1, "data array should have exactly one entry")
    }

    func testChangePassword_PayloadStructure_HasBothVOs() {
        let passwordDetails: ChangePasswordCredentials = (password: "new", passwordVerify: "new", passwordOld: "old")
        let endpoint = AccountEndpoint.changePassword(accountId: 1, passwordDetails: passwordDetails)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let firstEntry = data?.first

        XCTAssertNotNil(firstEntry?["AccountVO"], "Should contain AccountVO")
        XCTAssertNotNil(firstEntry?["AccountPasswordVO"], "Should contain AccountPasswordVO")
    }

    func testDeleteShareRequest_PayloadStructure_UsesCorrectKeys() {
        let endpoint = AccountEndpoint.deleteShareRequest(shareId: 1, folderLinkId: 2, archiveId: 3)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let shareVO = data?.first?["ShareVO"] as? [String: Any]

        // Verify the key names match the API expectation
        XCTAssertNotNil(shareVO?["shareId"])
        XCTAssertNotNil(shareVO?["folder_linkId"])
        XCTAssertNotNil(shareVO?["archiveId"])
    }

    func testRedeemCode_PayloadStructure_HasPromoVO() {
        let endpoint = AccountEndpoint.redeemCode(code: "TEST")
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let firstEntry = data?.first

        XCTAssertNotNil(firstEntry?["PromoVO"], "Should contain PromoVO key")
    }
}
