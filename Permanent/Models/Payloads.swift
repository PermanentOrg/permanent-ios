//
//  Payloads.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23/09/2020.
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
                        "passwordVerify": credentials.loginCredentials.password
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
                        "primaryEmail": updateData.email
                    ]
                ]],
                "apiKey": Constants.API.apiKey,
                "csrf": csrf
            ]
        ]
    }
    
    static func smsVerificationCodePayload(accountId: String, email: String) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [[
                    "AccountVO": [
                        "accountId": accountId,
                        "primaryEmail": email
                    ]
                ]],
                "apiKey": Constants.API.apiKey
            ]
        ]
    }
    
    static func verifyPayload(for credentials: VerifyCodeCredentials) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [[
                    "AccountVO": [
                        "primaryEmail": credentials.email
                    ],
                    "AuthVO": [
                        "type": credentials.type.value,
                        "token": credentials.code
                    ]
                ]],
                "apiKey": Constants.API.apiKey
            ]
        ]
    }
    
    static func navigateMinPayload(for params: NavigateMinParams) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [[
                    "FolderVO": [
                        "archiveNbr": params.archiveNo,
                        "folder_linkId": "\(params.folderLinkId)"
                    ]
                ]],
                "apiKey": Constants.API.apiKey,
                "csrf": params.csrf
            ]
        ]
    }
    
    static func getLeanItemsPayload(for params: GetLeanItemsParams) -> RequestParameters {
        let childItemsDict = params.folderLinkIds.map {
            [
                "folder_linkId": $0
            ]
        }
        
        let dict = [
            "RequestVO": [
                "data": [[
                    "FolderVO": [
                        "archiveNbr": params.archiveNo,
                        "sort": params.sortOption.apiValue,
                        "ChildItemVOs": childItemsDict,
                        "folder_linkId": params.folderLinkId
                    ]
                ]],
                "apiKey": Constants.API.apiKey,
                "csrf": params.csrf
            ]
        ]
        
        return dict
    }
    
    static func uploadFileMetaPayload(for params: FileMetaParams) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [[
                    "RecordVO": [
                        "parentFolderId": params.folderId,
                        "parentFolder_linkId": params.folderLinkId,
                        "displayName": params.filename,
                        "uploadFileName": params.filename
                    ]
                ]],
                "apiKey": Constants.API.apiKey,
                "csrf": params.csrf
            ]
        ]
    }

    static func getPresignedUrlPayload(for params: GetPresignedUrlParams) -> RequestParameters {
        let dict = [
            "RequestVO": [
                "data": [[
                    "RecordVO": [
                        "parentFolderId": params.folderId,
                        "parentFolder_linkId": params.folderLinkId,
                        "displayName": params.filename,
                        "uploadFileName": params.filename,
                        "size": params.fileSize,
                        "derivedCreatedDT": params.derivedCreatedDT
                    ],
                    "SimpleVO": [
                        "key": "type",
                        "value": params.fileMimeType ?? "application/octet-stream"
                    ]
                ]],
                "apiKey": Constants.API.apiKey,
                "csrf": params.csrf
            ]
        ]
        return dict
    }

    static func registerRecord(for params: RegisterRecordParams) -> RequestParameters {
        let dict = [
            "RequestVO": [
                "data": [
                    "RecordVO": [
                        "parentFolderId": params.folderId,
                        "parentFolder_linkId": params.folderLinkId,
                        "displayName": params.filename,
                        "uploadFileName": params.filename,
                        "derivedCreatedDT": "2020-11-23T09:31:38.000Z"
                    ],
                    "SimpleVO": [
                        "key": params.s3Url,
                        "value": params.destinationUrl
                    ]
                ],
                "apiKey": Constants.API.apiKey,
                "csrf": params.csrf
            ]
        ]

        return dict
    }

    
    static func newFolderPayload(for params: NewFolderParams) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [[
                    "FolderVO": [
                        "displayName": params.filename,
                        "parentFolder_linkId": params.folderLinkId
                    ]
                ]],
                "apiKey": Constants.API.apiKey,
                "csrf": params.csrf
            ]
        ]
    }
    static func updatePassword(accountId: String, updateData: ChangePasswordCredentials, csrf: String) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [[
                    "AccountVO": [
                        "accountId": accountId
                    ],
                    "AccountPasswordVO": [
                        "password": updateData.password,
                        "passwordVerify": updateData.passwordVerify,
                        "passwordOld":updateData.passwordOld
                    ]
                ]],
                "apiKey": Constants.API.apiKey,
                "csrf": csrf
            ]
        ]
    }
    static func getValidCsrf() -> RequestParameters  {
        return ["data":"none"]
    }
    static func getUserData(accountId: String,csrf: String) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [[
                    "AccountVO": [
                        "accountId": accountId
                    ]
                ]],
                "apiKey": Constants.API.apiKey,
                "csrf": csrf
            ]
        ]
    }
    static func updateUserData(accountId: String, updateUserData: UpdateUserData, csrf: String) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [[
                    "AccountVO": [
                        "accountId": accountId,
                        "fullName": updateUserData.fullName,
                        "primaryEmail": updateUserData.primaryEmail,
                        "primaryPhone": updateUserData.primaryPhone,
                        "address": updateUserData.address,
                        "city": updateUserData.city,
                        "state": updateUserData.state,
                        "zip": updateUserData.zip,
                        "country": updateUserData.country
                    ]
                ]],
                "apiKey": Constants.API.apiKey,
                "csrf": csrf
            ]
        ]
    }
    static func acceptShareRequest(shareId: Int,folderLinkId: Int,archiveId: Int,csrf: String) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [[
                    "ShareVO": [
                        "shareId": shareId,
                        "folder_linkId": folderLinkId,
                        "archiveId": archiveId,
                        "accessRole": "access.role.viewer",
                        "type": "type.share.record",
                        "status": "status.generic.ok"
                    ]
                ]],
                "apiKey": Constants.API.apiKey,
                "csrf": csrf
            ]
        ]
    }
    static func denyShareRequest(shareId: Int,folderLinkId: Int,archiveId: Int,csrf: String) -> RequestParameters{
        return [
            "RequestVO": [
                "data": [[
                    "ShareVO": [
                        "shareId": shareId,
                        "folder_linkId": folderLinkId,
                        "archiveId": archiveId
                    ]
                ]],
                "apiKey": Constants.API.apiKey,
                "csrf": csrf
            ]
        ]
    }
    
    static func updateRecordRequest(params: UpdateRecordParams) -> RequestParameters {
        var recordVO: [String: Any] = [
            "recordId": params.recordId,
            "archiveNbr": params.archiveNbr,
            "folder_linkId": params.folderLinkId
        ]
        
        if let name = params.name {
            recordVO["displayName"] = name
        }
        if let description = params.description {
            recordVO["description"] = description
        }
        if let date = params.date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            
            recordVO["displayDT"] = dateFormatter.string(from: date)
        }
        if let location = params.location,
           let locationJson = try? JSONEncoder().encode(location),
           let locationDict = try? JSONSerialization.jsonObject(with: locationJson, options: []) {
            recordVO["locnVO"] = locationDict
        }
        
        return [ "RequestVO":
                    [
                        "apiKey": Constants.API.apiKey,
                        "csrf": params.csrf,
                        "data": [
                            [
                                "RecordVO": recordVO
                            ]
                        ]
                    ]
        ]
    }
    
    static func geomapLatLong(params: GeomapLatLongParams) -> RequestParameters {
        let locnVO: [String: Any] = [
            "latitude": params.lat,
            "longitude": params.long
        ]
        
        return [ "RequestVO":
                    [
                        "apiKey": Constants.API.apiKey,
                        "csrf": params.csrf,
                        "data": [
                            [
                                "LocnVO": locnVO
                            ]
                        ]
                    ]
        ]
    }
}
