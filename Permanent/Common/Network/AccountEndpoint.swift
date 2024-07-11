//
//  AccountEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 30/09/2020.
//

import Foundation

typealias LoginCredentials = (email: String, password: String)
typealias SignUpCredentials = (name: String, loginCredentials: LoginCredentials)
typealias SignUpV2Credentials = (name: String, email: String, password: String)
typealias ChangePasswordCredentials = (password: String, passwordVerify: String, passwordOld: String)
typealias UpdateData = (email: String, phone: String)
typealias UpdateUserData = (fullName: String?, primaryEmail: String?, primaryPhone: String?, address: String?, address2: String?, city: String?, state: String?, zip: String?, country: String?)

enum AccountEndpoint {
    /// Creates an new user account.
    case signUp(credentials: SignUpCredentials)
    /// Creates an new user account.
    case signUpV2(credentials: SignUpV2Credentials)
    /// Deletes user account
    case delete(accountId: Int)
    /// Updates user account.
    case updateEmailAndPhone(accountId: Int, data: UpdateData)
    /// Updates user account.
    case update(accountVO: AccountVOData)
    /// Sends an SMS with a verification code for verifying the phone number.
    case sendVerificationCodeSMS(accountId: Int, email: String)
    /// Change user password
    case changePassword(accountId: Int, passwordDetails: ChangePasswordCredentials)
    /// Get user data
    case getUserData(accountId: Int)
    /// Updates user data
    case updateUserData(accountId: Int, updateData: UpdateUserData)
    /// Update Share request
    case updateShareRequest(shareVO: ShareVOData)
    case updateShareArchiveRequest(archiveVO: MinArchiveVO)
    /// Revoke Share request
    case deleteShareRequest(shareId: Int, folderLinkId: Int, archiveId: Int)
    ///  Redeem code request
    case redeemCode(code: String)
    case getSessionAccount
    case addRemoveTags(archiveType:String, addGoalTags: [String]?, addWhyTags: [String]?, removeGoalTags: [String]?, removeWhyTags: [String]?)
}

extension AccountEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .signUp:
            return "/account/post"
        case .signUpV2:
            return "/account/post"
        case .delete:
            return "/account/delete"
        case .update, .updateEmailAndPhone:
            return "/account/update"
        case .sendVerificationCodeSMS:
            return "/auth/resendTextCreatedAccount"
        case .changePassword:
            return "/account/changePassword"
        case .getUserData:
            return "/account/get"
        case .updateUserData:
            return "/account/update"
        case .updateShareRequest, .updateShareArchiveRequest:
            return "/share/upsert"
        case .deleteShareRequest:
            return "/share/delete"
        case .getSessionAccount:
            return "/account/getsessionaccount"
        case .redeemCode:
            return "/promo/entry"
        case .addRemoveTags:
            return "/account/tags"
        }
    }

    var parameters: RequestParameters? {
        switch self {
        case .signUp(let credentials):
            return signUpPayload(for: credentials)
            
        case .signUpV2(let credentials):
            return signUpV2Payload(for: credentials)
            
        case .delete(let accountId):
            return deleteAccountPayload(accountId: accountId)
            
        case .updateEmailAndPhone(let accountId, let data):
            return updateEmailAndPhone(accountId: accountId, updateData: data)
            
        case .update(let accountVO):
            return update(accountVO: accountVO)
            
        case .sendVerificationCodeSMS(let id, let email):
            return smsVerificationCodePayload(accountId: id, email: email)
            
        case .changePassword(let id, let passData):
            return updatePassword(accountId: id, updateData: passData)
            
        case .getUserData(let id):
            return getUserData(accountId: id)
            
        case .updateUserData(accountId: let accountId, updateData: let updateData):
            return updateUserData(accountId: accountId, updateUserData: updateData)
            
        case .updateShareRequest(let shareVO):
            return updateShareRequest(shareVO: shareVO)
            
        case .updateShareArchiveRequest(let archiveVO):
            return updateShareRequest(minArchiveVO: archiveVO)
            
        case .deleteShareRequest(shareId: let shareId, folderLinkId: let folderLinkId, archiveId: let archiveId):
            return deleteShareRequest(shareId: shareId, folderLinkId: folderLinkId, archiveId: archiveId)
            
        case .getSessionAccount:
            return getSessionAccount()
            
        case .redeemCode(code: let code):
            return redeemCode(code: code)
            
        case .addRemoveTags(archiveType: let archiveType, addGoalTags: let addGoalTags, addWhyTags: let addWhyTags, removeGoalTags: let removeGoalTags, removeWhyTags: let removeWhyTags):
            return addRemoveTags(archiveType: archiveType, addGoalTags: addGoalTags, addWhyTags: addWhyTags, removeGoalTags: removeGoalTags, removeWhyTags: removeWhyTags)
        }
    }

    var method: RequestMethod {
        switch self {
        case .addRemoveTags:
            return .put
        default:
            return .post
        }
    }

    var requestType: RequestType { .data }

    var responseType: ResponseType { .json }
    
    var progressHandler: ProgressHandler? {
        get { nil }
        // swiftlint:disable:next unused_setter_value
        set { }
    }
    
    var headers: RequestHeaders? {
        if method == .post || method == .put {
            if case .signUpV2(_) = self {
                return [
                    "content-type": "application/json; charset=utf-8",
                    "Request-Version": "2"
                ]
            } else {
                return ["content-type": "application/json; charset=utf-8"]
            }
        } else {
            return nil
        }
    }
    
    var bodyData: Data? { nil }
    
    var customURL: String? {
        let endpointPath = APIEnvironment.defaultEnv.apiServer
        switch self {
        case .addRemoveTags(_, _, _, _, _):
            return "\(endpointPath)api/v2/account/tags"
        default : return nil
        }
    }
}

extension AccountEndpoint {
    func signUpPayload(for credentials: SignUpCredentials) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [
                        "AccountVO": [
                            "primaryEmail": credentials.loginCredentials.email,
                            "fullName": credentials.name,
                            "agreed": true,
                            "optIn": false
                        ],
                        "AccountPasswordVO": [
                            "password": credentials.loginCredentials.password,
                            "passwordVerify": credentials.loginCredentials.password
                        ],
                        "SimpleVO": [
                            "key": "createArchive",
                            "value": false
                        ]
                    ]
                ]
            ]
        ]
    }
    
    func signUpV2Payload(for credentials: SignUpV2Credentials) -> RequestParameters {
        return [
            "agreed": true,
            "createArchive": false,
            "fullName": credentials.name,
            "optIn": false,
            "primaryEmail": credentials.email,
            "password": credentials.password,
            "passwordVerify": credentials.password
        ]
    }
    
    func deleteAccountPayload(accountId: Int) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [
                        "AccountVO": [
                            "accountId": accountId
                        ]
                    ]
                ]
            ]
        ]
    }
    
    func updateEmailAndPhone(accountId: Int, updateData: UpdateData) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [
                        "AccountVO": [
                            "accountId": accountId,
                            "primaryPhone": updateData.phone,
                            "primaryEmail": updateData.email
                        ]
                    ]
                ]
            ]
        ]
    }
    
    func update(accountVO: AccountVOData) -> RequestParameters {
        let accountDict: Any?
        if let accountJson = try? JSONEncoder().encode(accountVO) {
            accountDict = try? JSONSerialization.jsonObject(with: accountJson, options: [])
        } else {
            accountDict = nil
        }
        
        return [
            "RequestVO": [
                "data": [
                    [
                        "AccountVO": accountDict
                    ]
                ]
            ]
        ]
    }
    
    func smsVerificationCodePayload(accountId: Int, email: String) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [
                        "AccountVO": [
                            "accountId": accountId,
                            "primaryEmail": email
                        ]
                    ]
                ]
            ]
        ]
    }
    
    func updatePassword(accountId: Int, updateData: ChangePasswordCredentials) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [
                        "AccountVO": [
                            "accountId": accountId
                        ],
                        "AccountPasswordVO": [
                            "password": updateData.password,
                            "passwordVerify": updateData.passwordVerify,
                            "passwordOld": updateData.passwordOld
                        ]
                    ]
                ]
            ]
        ]
    }
    
    func getUserData(accountId: Int) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [
                        "AccountVO": [
                            "accountId": accountId
                        ]
                    ]
                ]
            ]
        ]
    }
    
    func updateUserData(accountId: Int, updateUserData: UpdateUserData) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [
                        "AccountVO": [
                            "accountId": accountId,
                            "fullName": updateUserData.fullName as Any,
                            "primaryEmail": updateUserData.primaryEmail as Any,
                            "primaryPhone": updateUserData.primaryPhone as Any,
                            "address": updateUserData.address as Any,
                            "address2": updateUserData.address2 as Any,
                            "city": updateUserData.city as Any,
                            "state": updateUserData.state as Any,
                            "zip": updateUserData.zip as Any,
                            "country": updateUserData.country as Any
                        ]
                    ]
                ]
            ]
        ]
    }
    
    func updateShareRequest(shareVO: ShareVOData) -> RequestParameters {
        guard let shareVOJson = try? JSONEncoder().encode(shareVO),
            let shareVODict = try? JSONSerialization.jsonObject(with: shareVOJson, options: []) else {
            return []
        }
        
        let updateDict = [
            "RequestVO": [
                "data": [
                    [
                        "ShareVO": shareVODict
                    ]
                ]
            ]
        ]
        return updateDict
    }
    
    func updateShareRequest(minArchiveVO: MinArchiveVO) -> RequestParameters {
        let shareVO = ShareVOData(shareID: minArchiveVO.shareId, folderLinkID: minArchiveVO.folderLinkID, archiveID: minArchiveVO.archiveID, accessRole: minArchiveVO.accessRole, type: nil, status: minArchiveVO.shareStatus, requestToken: nil, previewToggle: nil, folderVO: nil, recordVO: nil, archiveVO: nil, accountVO: nil, createdDT: nil, updatedDT: nil)
        
        guard let shareVOJson = try? JSONEncoder().encode(shareVO),
            let shareVODict = try? JSONSerialization.jsonObject(with: shareVOJson, options: []) else {
            return []
        }
        
        let updateDict = [
            "RequestVO": [
                "data": [
                    [
                        "ShareVO": shareVODict
                    ]
                ]
            ]
        ]
        return updateDict
    }
    
    func deleteShareRequest(shareId: Int, folderLinkId: Int, archiveId: Int) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [
                        "ShareVO": [
                            "shareId": shareId,
                            "folder_linkId": folderLinkId,
                            "archiveId": archiveId
                        ]
                    ]
                ]
            ]
        ]
    }
    
    func getSessionAccount() -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [:]
                ]
            ]
        ]
    }
    
    func redeemCode(code: String) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [
                        "PromoVO": [
                            "code": code
                        ]
                    ]
                ]
            ]
        ]
    }
    
    func addRemoveTags(archiveType: String, addGoalTags: [String]?, addWhyTags: [String]?, removeGoalTags: [String]?, removeWhyTags: [String]?) -> RequestParameters {
        var addFormattedTags: [String] = []
        var removeFormattedTags: [String] = []
        var result: RequestParameters = []
        
        addFormattedTags.append(archiveType)
        
        if let addGoals = addGoalTags {
            addFormattedTags.append(contentsOf: addGoals.map { "goal:\($0)" })
        }
        
        if let addWhys = addWhyTags {
            addFormattedTags.append(contentsOf: addWhys.map { "why:\($0)" })
        }
        
        if let removeGoals = removeGoalTags {
            removeFormattedTags.append(contentsOf: removeGoals.map { "goal:\($0)" })
        }
        
        if let removeWhys = removeWhyTags {
            removeFormattedTags.append(contentsOf: removeWhys.map { "why:\($0)" })
        }
    
        result = [
            "addTags": addFormattedTags,
            "removeTags": removeFormattedTags
        ]
        
        return result
    }
}
