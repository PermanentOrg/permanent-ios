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
                "data": [
                    [
                        "AccountVO": [
                            "primaryEmail": email
                        ]
                    ]
                ]
            ]
        ]
    }
    
    static func loginPayload(for credentials: LoginCredentials) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [
                        "AccountVO": [
                            "primaryEmail": credentials.email
                        ],
                        "AccountPasswordVO": [
                            "password": credentials.password
                        ]
                    ]
                ]
            ]
        ]
    }
    
    static func signUpPayload(for credentials: SignUpCredentials) -> RequestParameters {
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
    
    static func deleteAccountPayload(accountId: Int) -> RequestParameters {
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
    
    static func updateEmailAndPhone(accountId: Int, updateData: UpdateData) -> RequestParameters {
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
    
    static func update(accountVO: AccountVOData) -> RequestParameters {
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
    
    static func smsVerificationCodePayload(accountId: Int, email: String) -> RequestParameters {
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
    
    static func navigateMinPayload(for params: NavigateMinParams) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [
                        "FolderVO": [
                            "archiveNbr": params.archiveNo,
                            "folder_linkId": "\(params.folderLinkId)"
                        ]
                    ]
                ]
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
                "data": [
                    [
                        "FolderVO": [
                            "archiveNbr": params.archiveNo,
                            "sort": params.sortOption.apiValue,
                            "ChildItemVOs": childItemsDict,
                            "folder_linkId": params.folderLinkId
                        ]
                    ]
                ]
            ]
        ]
        
        return dict
    }
    
    static func uploadFileMetaPayload(for params: FileMetaParams) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [
                        "RecordVO": [
                            "parentFolderId": params.folderId,
                            "parentFolder_linkId": params.folderLinkId,
                            "displayName": params.filename,
                            "uploadFileName": params.filename
                        ]
                    ]
                ]
            ]
        ]
    }

    static func getPresignedUrlPayload(for params: GetPresignedUrlParams) -> RequestParameters {
        let dict = [
            "RequestVO": [
                "data": [
                    [
                        "RecordVO": [
                            "parentFolderId": params.folderId,
                            "parentFolder_linkId": params.folderLinkId,
                            "displayName": params.filename,
                            "uploadFileName": params.filename,
                            "size": params.fileSize,
                            "derivedCreatedDT": params.derivedCreatedDT as Any
                        ],
                        "SimpleVO": [
                            "key": "type",
                            "value": params.fileMimeType ?? "application/octet-stream"
                        ]
                    ]
                ]
            ]
        ]
        return dict
    }

    static func registerRecord(for params: RegisterRecordParams) -> RequestParameters {
        var recordVO: [String: Any] = [
            "parentFolderId": params.folderId,
            "parentFolder_linkId": params.folderLinkId,
            "displayName": params.filename,
            "uploadFileName": params.filename
        ]
        if let createdDT = params.derivedCreatedDT {
            recordVO["derivedCreatedDT"] = createdDT
        }
        
        let dict = [
            "RequestVO": [
                "data": [
                    "RecordVO": recordVO,
                    "SimpleVO": [
                        "key": params.s3Url,
                        "value": params.destinationUrl
                    ]
                ]
            ]
        ]

        return dict
    }

    static func newFolderPayload(for params: NewFolderParams) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [
                        "FolderVO": [
                            "displayName": params.filename,
                            "parentFolder_linkId": params.folderLinkId
                        ]
                    ]
                ]
            ]
        ]
    }
    
    static func updatePassword(accountId: Int, updateData: ChangePasswordCredentials) -> RequestParameters {
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
    
    static func getUserData(accountId: Int) -> RequestParameters {
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
    static func updateUserData(accountId: Int, updateUserData: UpdateUserData) -> RequestParameters {
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
    static func updateShareRequest(shareVO: ShareVOData) -> RequestParameters {
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
    
    static func deleteShareRequest(shareId: Int, folderLinkId: Int, archiveId: Int) -> RequestParameters {
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
    
    static func getSessionAccount() -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [:]
                ]
            ]
        ]
    }
    
    static func verifyAuth() -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [:]
                ]
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
        
        return [
            "RequestVO":
                [
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
        
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "LocnVO": locnVO
                        ]
                    ]
                ]
        ]
    }
    
    static func locnPost(location: LocnVO) -> RequestParameters {
        guard let locationJson = try? JSONEncoder().encode(location),
            let locationDict = try? JSONSerialization.jsonObject(with: locationJson, options: []) else { return [] }

        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "LocnVO": locationDict
                        ]
                    ]
                ]
        ]
    }
    
    static func devicePayload(params: NewDeviceParams) -> RequestParameters {
        return
            [
                "RequestVO":
                    [
                        "data": [
                            [
                                "SimpleVO": [
                                    "name": "token",
                                    "value": params
                                ]
                            ]
                        ]
                    ]
            ]
    }
    
    static func tagPost(params: TagParams) -> RequestParameters {
        let tagLinkVO: [String: Any] = [
            "refId": params.refID,
            "refTable": "record"
        ]
        
        let data = params.names.map {
            [
                "TagLinkVO": tagLinkVO,
                "TagVO": [
                    "name": $0
                ]
            ]
        }
        
        return [
            "RequestVO":
                [
                    "data": data
                ]
        ]
    }
    
    static func deletePost(params: DeleteTagParams) -> RequestParameters {
        let tagLinkVO: [String: Any] = [
            "refId": params.refID,
            "refTable": "record"
        ]
        
        let data = params.tagVO.map {
            [
                "TagLinkVO": tagLinkVO,
                "TagVO": [
                    "name": ($0.tagVO.name ?? String() ) as String,
                    "tagId": ($0.tagVO.tagId ?? Int() ) as Int
                ]
            ]
        }
        
        return [
            "RequestVO":
                [
                    "data": data
                ]
        ]
    }
    
    static func getTagsByArchive(params: GetTagsByArchiveParams) -> RequestParameters {
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "ArchiveVO": [
                                "archiveId": params
                            ]
                        ]
                    ]
                ]
        ]
    }
    
    static func getArchivesByAccountId(accountId: GetArchivesByAccountId) -> RequestParameters {
        return [
            "RequestVO":
                [
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
    
    static func changeArchivePayload(archiveId: Int, archiveNbr: String) -> RequestParameters {
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "ArchiveVO": [
                                "archiveId": archiveId,
                                "archiveNbr": archiveNbr
                            ]
                        ]
                    ]
                ]
        ]
    }
    
    static func updateArchiveThumbPayload(archiveVO: ArchiveVOData, file: FileViewModel) -> RequestParameters {
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "ArchiveVO": [
                                "archiveId": archiveVO.archiveID!,
                                "archiveNbr": archiveVO.archiveNbr!,
                                "thumbArchiveNbr": file.archiveNo
                            ]
                        ]
                    ]
                ]
        ]
    }
    
    static func createArchivePayload(name: String, type: String) -> RequestParameters {
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "ArchiveVO": [
                                "fullName": name,
                                "type": type,
                                "relationType": NSNull()
                            ]
                        ]
                    ]
                ]
        ]
    }
    
    static func deleteArchivePayload(archiveId: Int, archiveNbr: String) -> RequestParameters {
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "ArchiveVO": [
                                "archiveId": archiveId,
                                "archiveNbr": archiveNbr
                            ]
                        ]
                    ]
                ]
        ]
    }
    
    static func unshareRecord(archiveId: Int, folderLinkId: Int) -> RequestParameters {
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "ShareVO": [
                                "folder_linkId": folderLinkId,
                                "archiveId": archiveId
                            ]
                        ]
                    ]
                ]
        ]
    }
    
    static func acceptArchivePayload(archiveVO: ArchiveVOData) -> RequestParameters {
        var modifiedArchive: Any = []
        let archive = archiveVO
        if let archiveJson = try? JSONEncoder().encode(archive),
            let archiveDict = try? JSONSerialization.jsonObject(with: archiveJson, options: []) {
            modifiedArchive = archiveDict
        }
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "ArchiveVO": modifiedArchive
                        ]
                    ]
                ]
        ]
    }
    
    static func declineArchivePayload(archiveVO: ArchiveVOData) -> RequestParameters {
        var modifiedArchive: Any = []
        let archive = archiveVO
        if let archiveJson = try? JSONEncoder().encode(archive),
            let archiveDict = try? JSONSerialization.jsonObject(with: archiveJson, options: []) {
            modifiedArchive = archiveDict
        }
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "ArchiveVO": modifiedArchive
                        ]
                    ]
                ]
        ]
    }
    
    static func transferOwnership(archiveNbr: String, primaryEmail: String) -> RequestParameters {
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "ArchiveVO": [
                                "archiveNbr": archiveNbr
                            ],
                            "AccountVO": [
                                "primaryEmail": primaryEmail,
                                "accessRole": AccessRole.apiRoleForValue(.owner)
                            ]
                        ]
                    ]
                ]
        ]
    }
    
    static func renameFolderRequest(params: UpdateRecordParams) -> RequestParameters {
        var folderVO: [String: Any] = [
            "folderId": params.recordId,
            "archiveNbr": params.archiveNbr,
            "folder_linkId": params.folderLinkId
        ]
        
        if let name = params.name {
            folderVO["displayName"] = name
        }
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "FolderVO": folderVO
                        ]
                    ]
                ]
        ]
    }
    
    static func getAllByArchiveNbr(archiveId: Int, archiveNbr: String) -> RequestParameters {
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "Profile_itemVO": [
                                "archiveId": archiveId,
                                "archiveNbr": archiveNbr
                            ]
                        ]
                    ]
                ]
        ]
    }
    
    static func getArchivesByArchivesNbr(archivesNbr: [String]) -> RequestParameters {
        let data = archivesNbr.map {
            [
                "ArchiveVO": [
                    "archiveNbr": $0
                ]
            ]
        }
        
        return [
            "RequestVO":
                [
                    "data": data
                ]
        ]
    }
    
    static func searchArchive(searchName: String) -> RequestParameters {
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "SearchVO": [
                                "query": searchName
                            ]
                        ]
                    ]
                ]
        ]
    }
    
    static func safeAddUpdate(profileItemVOData: ProfileItemModel) -> RequestParameters {
        let profileDict: Any?
        if let profileJson = try? JSONEncoder().encode(profileItemVOData) {
            profileDict = try? JSONSerialization.jsonObject(with: profileJson, options: [])
        } else {
            profileDict = nil
        }
        
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "Profile_itemVO": profileDict
                        ]
                    ]
                ]
        ]
    }
    
    static func updateProfileVisibility(profileItemVOData: [ProfileItemModel], isVisible: Bool) -> RequestParameters {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        let publicDT: Any = isVisible ? dateFormatter.string(from: Date()) : NSNull()
        let profileVOItems: [[String: Any]] = profileItemVOData.map { model in
            return ["Profile_itemVO": ["profile_itemId": model.profileItemId ?? 0, "publicDT": publicDT]]
        }
        
        return [
            "RequestVO":
                [
                    "data": profileVOItems
                ]
        ]
    }
        
    static func searchFolderAndRecord(text: String, tags: [TagVOData]) -> RequestParameters {
        var tagVOs: Any = []
        if let json = try? JSONEncoder().encode(tags),
            let jsonDict = try? JSONSerialization.jsonObject(with: json, options: []) {
            tagVOs = jsonDict
        }
        
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "SearchVO": [
                                "query": text,
                                "numberOfResults": 10,
                                "TagVOs": tagVOs
                            ]
                        ]
                    ]
                ]
        ]
    }
    
    static func updateRootColumns(_ params: UpdateRootColumnsParams) -> RequestParameters {
        return [
            "RequestVO":
                [
                    "data":
                        [
                            [
                                "FolderVO":
                                    [
                                        "archiveNbr": params.folderArchiveNbr,
                                        "folderId": params.folderId,
                                        "folder_linkId": params.folderLinkId,
                                        "thumbArchiveNbr": params.thumbArchiveNbr
                                    ]
                            ]
                        ]
                ]
        ]
    }
}
