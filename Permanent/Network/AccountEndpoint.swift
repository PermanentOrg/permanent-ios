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
        }
    }

    var method: RequestMethod { .post }

    var headers: RequestHeaders? { nil }

    var requestType: RequestType { .data }

    var responseType: ResponseType { .json }
}
