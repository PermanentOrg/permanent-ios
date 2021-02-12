//
//  AccountEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 30/09/2020.
//

import Foundation

typealias SignUpCredentials = (name: String, loginCredentials: LoginCredentials)

enum AccountEndpoint {
    /// Creates an new user account.
    case signUp(credentials: SignUpCredentials)
    /// Updates user account.
    case update(accountId: String, updateData: UpdateData, csrf: String)
    /// Sends an SMS with a verification code for verifying the phone number.
    case sendVerificationCodeSMS(accountId: String, email: String)
    /// Change user password
    case changePassword(accountId: String, passwordDetails: ChangePasswordCredentials, csrf: String )
    /// Get valid CSRF parameter
    case getValidCsrf
    /// Get user data
    case getUserData(accountId: String, csrf: String)
    /// Updates user data
    case updateUserData(accountId: String, updateData: UpdateUserData, csrf: String)
    /// Update Share request
    case updateShareRequest(shareId: Int,folderLinkId: Int,archiveId: Int,csrf: String)
    /// Revoke Share request
    case deleteShareRequest(shareId: Int,folderLinkId: Int,archiveId: Int,csrf: String)
}

extension AccountEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .signUp:
            return "/account/post"
        case .update:
            return "/account/update"
        case .sendVerificationCodeSMS:
            return "/auth/resendTextCreatedAccount"
        case .changePassword:
            return "/account/changePassword"
        case .getValidCsrf:
            return "/auth/loggedIn"
        case .getUserData:
            return "/account/get"
        case .updateUserData:
            return "/account/update"
        case .updateShareRequest:
            return "/share/upsert"
        case .deleteShareRequest:
            return "/share/delete"
        }
    }

    var parameters: RequestParameters? {
        switch self {
        case .signUp(let credentials):
            return Payloads.signUpPayload(for: credentials)
        case .update(let id, let data, let csrf):
            return Payloads.update(accountId: id, updateData: data, csrf: csrf)
        case .sendVerificationCodeSMS(let id, let email):
            return Payloads.smsVerificationCodePayload(accountId: id, email: email)
        case .changePassword(let id, let passData, let csrf):
            return Payloads.updatePassword(accountId: id,updateData: passData , csrf: csrf)
        case .getValidCsrf:
            return Payloads.getValidCsrf()
        case .getUserData(let id, let csrf):
            return Payloads.getUserData(accountId: id,csrf: csrf)
        case .updateUserData(accountId: let accountId, updateData: let updateData, csrf: let csrf):
            return Payloads.updateUserData(accountId: accountId,updateUserData: updateData,csrf: csrf)
        case .updateShareRequest(shareId: let shareId, folderLinkId: let folderLinkId, archiveId: let archiveId, csrf: let csrf):
            return Payloads.acceptShareRequest(shareId: shareId, folderLinkId: folderLinkId, archiveId: archiveId, csrf: csrf)
        case .deleteShareRequest(shareId: let shareId, folderLinkId: let folderLinkId, archiveId: let archiveId, csrf: let csrf):
            return Payloads.denyShareRequest(shareId: shareId, folderLinkId: folderLinkId, archiveId: archiveId, csrf: csrf)
        }
    }

    var method: RequestMethod { .post }

    var headers: RequestHeaders? { nil }

    var requestType: RequestType { .data }

    var responseType: ResponseType { .json }
    
    var progressHandler: ProgressHandler? {
        get { nil }
        set {}
    }
    
    var bodyData: Data? { nil }
    
    var customURL: String? { nil }
}
