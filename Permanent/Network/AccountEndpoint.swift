//
//  AccountEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 30/09/2020.
//

import Foundation

typealias SignUpCredentials = (name: String, loginCredentials: LoginCredentials)
typealias UpdateData = (email: String, phone: String)

enum AccountEndpoint {
    /// Creates an new user account.
    case signUp(credentials: SignUpCredentials)
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
    /// Revoke Share request
    case deleteShareRequest(shareId: Int, folderLinkId: Int, archiveId: Int)
    case getSessionAccount
}

extension AccountEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .signUp:
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
        case .updateShareRequest:
            return "/share/upsert"
        case .deleteShareRequest:
            return "/share/delete"
        case .getSessionAccount:
            return "/account/getsessionaccount"
        }
    }

    var parameters: RequestParameters? {
        switch self {
        case .signUp(let credentials):
            return Payloads.signUpPayload(for: credentials)
            
        case .delete(let accountId):
            return Payloads.deleteAccountPayload(accountId: accountId)
            
        case .updateEmailAndPhone(let accountId, let data):
            return Payloads.updateEmailAndPhone(accountId: accountId, updateData: data)
            
        case .update(let accountVO):
            return Payloads.update(accountVO: accountVO)
            
        case .sendVerificationCodeSMS(let id, let email):
            return Payloads.smsVerificationCodePayload(accountId: id, email: email)
            
        case .changePassword(let id, let passData):
            return Payloads.updatePassword(accountId: id, updateData: passData)
            
        case .getUserData(let id):
            return Payloads.getUserData(accountId: id)
            
        case .updateUserData(accountId: let accountId, updateData: let updateData):
            return Payloads.updateUserData(accountId: accountId, updateUserData: updateData)
            
        case .updateShareRequest(let shareVO):
            return Payloads.updateShareRequest(shareVO: shareVO)
            
        case .deleteShareRequest(shareId: let shareId, folderLinkId: let folderLinkId, archiveId: let archiveId):
            return Payloads.deleteShareRequest(shareId: shareId, folderLinkId: folderLinkId, archiveId: archiveId)
            
        case .getSessionAccount:
            return Payloads.getSessionAccount()
        }
    }

    var method: RequestMethod { .post }

    var requestType: RequestType { .data }

    var responseType: ResponseType { .json }
    
    var progressHandler: ProgressHandler? {
        get { nil }
        // swiftlint:disable:next unused_setter_value
        set { }
    }
    
    var bodyData: Data? { nil }
    
    var customURL: String? { nil }
}
