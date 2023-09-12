//
//  ArchivesEndpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.08.2021.
//

import Foundation

typealias GetArchivesByAccountId = (Int)

enum ArchivesEndpoint {
    case getArchivesByAccountId(accountId: GetArchivesByAccountId)
    case change(archiveId: Int, archiveNbr: String)
    case create(name: String, type: String)
    case delete(archiveId: Int, archiveNbr: String)
    case accept(archiveVO: ArchiveVOData)
    case decline(archiveVO: ArchiveVOData)
    case update(archiveVO: ArchiveVOData, file: FileModel)
    case transferOwnership(archiveNbr: String, primaryEmail: String)
    case getArchivesByArchivesNbr(archivesNbr: [String])
    case searchArchive(searchAfter: String)
}

extension ArchivesEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .getArchivesByAccountId:
            return "/archive/getAllArchives"
            
        case .change:
            return "/archive/change"
            
        case .create:
            return "/archive/post"
            
        case .delete:
            return "/archive/delete"
            
        case .accept:
            return "/archive/accept"
            
        case .decline:
            return "/archive/decline"
            
        case .update:
            return "/archive/update"
            
        case .transferOwnership:
            return "/archive/transferOwnership"
            
        case .getArchivesByArchivesNbr:
            return "/archive/get"
            
        case .searchArchive:
            return "/search/archive"
        }
    }
    
    var method: RequestMethod {
        return .post
    }
    
    var requestType: RequestType {
        return .data
    }
    
    var responseType: ResponseType {
        return .json
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .getArchivesByAccountId(let accountId):
            return getArchivesByAccountId(accountId: accountId)
            
        case .change(let archiveId, let archiveNbr):
            return changeArchivePayload(archiveId: archiveId, archiveNbr: archiveNbr)
            
        case .create(let name, let type):
            return createArchivePayload(name: name, type: type)
            
        case .delete(let archiveId, let archiveNbr):
            return deleteArchivePayload(archiveId: archiveId, archiveNbr: archiveNbr)
            
        case .accept(archiveVO: let archiveVO):
            return acceptArchivePayload(archiveVO: archiveVO)
            
        case .decline(archiveVO: let archiveVO):
            return declineArchivePayload(archiveVO: archiveVO)
            
        case .update(let archiveVO, let file):
            return updateArchiveThumbPayload(archiveVO: archiveVO, file: file)
            
        case .transferOwnership(archiveNbr: let archiveNbr, primaryEmail: let primaryEmail):
            return transferOwnership(archiveNbr: archiveNbr, primaryEmail: primaryEmail)
            
        case .getArchivesByArchivesNbr(archivesNbr: let archivesNbr):
            return getArchivesByArchivesNbr(archivesNbr: archivesNbr)
            
        case .searchArchive(searchAfter: let searchAfter):
            return searchArchive(searchName: searchAfter)
        }
    }
    
    var progressHandler: ProgressHandler? {
        get {
            nil
        }
        set {}
    }
    
    var bodyData: Data? {
        nil
    }
    
    var customURL: String? {
        nil
    }
}

extension ArchivesEndpoint {
    func getArchivesByAccountId(accountId: GetArchivesByAccountId) -> RequestParameters {
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
    
    func changeArchivePayload(archiveId: Int, archiveNbr: String) -> RequestParameters {
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
    
    func createArchivePayload(name: String, type: String) -> RequestParameters {
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
    
    func deleteArchivePayload(archiveId: Int, archiveNbr: String) -> RequestParameters {
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
    
    func acceptArchivePayload(archiveVO: ArchiveVOData) -> RequestParameters {
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
    
    func declineArchivePayload(archiveVO: ArchiveVOData) -> RequestParameters {
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
    
    func transferOwnership(archiveNbr: String, primaryEmail: String) -> RequestParameters {
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
    
    func updateArchiveThumbPayload(archiveVO: ArchiveVOData, file: FileModel) -> RequestParameters {
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
    
    func getArchivesByArchivesNbr(archivesNbr: [String]) -> RequestParameters {
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
    
    func searchArchive(searchName: String) -> RequestParameters {
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
}
