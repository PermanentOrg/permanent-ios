//
//  Payloads.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23/09/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import Foundation

struct Payloads {
    static func forgotPasswordPayload(for email: String) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [[
                    "AccountVO": [
                        "primaryEmail": email
                    ]
                ]],
                "apiKey": Constants.API.apiKey
            ]
        ]
    }
    
    static func loginPayload(for credentials: LoginCredentials) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [[
                    "AccountVO": [
                        "primaryEmail": credentials.email
                    ],
                    "AccountPasswordVO": [
                        "password": credentials.password
                    ]
                ]],
                "apiKey": Constants.API.apiKey
            ]
        ]
    }
    
    static func signUpPayload(for credentials: SignUpCredentials) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [[
                    "AccountVO": [
                        "primaryEmail": credentials.loginCredentials.email,
                        "fullName": credentials.name,
                        "agreed": true,
                        "optIn": false
                    ],
                    "AccountPasswordVO": [
                        "password": credentials.loginCredentials.password,
                        "passwordVerify": credentials.loginCredentials.password,
                    ]
                ]],
                "apiKey": Constants.API.apiKey
            ]
        ]
    }
    
    static func update(accountId: String, updateData: UpdateData, csrf: String) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [[
                    "AccountVO": [
                        "accountId": accountId,
                        "primaryPhone": updateData.phone,
                        "primaryEmail": updateData.email,
                    ]
                ]],
                "apiKey": Constants.API.apiKey,
                "csrf": csrf
            ]
        ]
    }
    
    
    static func verifyPayload(for credentials: VerifyCodeCredentials) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [[
                    "AccountVO": [
                        "primaryEmail": credentials.email,
                    ],
                    "AuthVO": [
                        "type": "type.auth.mfaValidation",
                        "token": credentials.code
                    ]
                ]],
                "apiKey": Constants.API.apiKey
            ]
        ]
    }
}
