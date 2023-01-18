//
//  FilesEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

typealias NewFolderParams = (filename: String, folderLinkId: Int)
typealias NavigateMinParams = (archiveNo: String, folderLinkId: Int, folderName: String?)
typealias GetLeanItemsParams = (archiveNo: String, sortOption: SortOption, folderLinkIds: [Int], folderLinkId: Int)
typealias FileMetaParams = (folderId: Int, folderLinkId: Int, filename: String)
typealias GetPresignedUrlParams = (folderId: Int, folderLinkId: Int, fileMimeType: String?, filename: String, fileSize: Int, derivedCreatedDT: String?)
typealias RegisterRecordParams = (folderId: Int, folderLinkId: Int, filename: String, derivedCreatedDT: String?, s3Url: String, destinationUrl: String)
typealias GetRecordParams = (folderLinkId: Int, parentFolderLinkId: Int)
typealias ItemInfoParams = (FileViewModel)
typealias RelocateParams = (items: ItemPair, action: FileAction)
typealias ItemPair = (source: FileViewModel, destination: FileViewModel)

typealias UpdateRecordParams = (name: String?, description: String?, date: Date?, location: LocnVO?, recordId: Int, folderLinkId: Int, archiveNbr: String)
typealias UpdateRootColumnsParams = (thumbArchiveNbr: String, folderId: Int, folderArchiveNbr: String, folderLinkId: Int)

enum FilesEndpoint {
    // NAVIGATION
    /// Retrieves the “root” of an archive: the parent folder that contains the My Files and Public folders.
    case getRoot
    case getPublicRoot(archiveNbr: String)
    case navigateMin(params: NavigateMinParams)
    case getLeanItems(params: GetLeanItemsParams)
    
    // FILES MANAGEMENT
    case newFolder(params: NewFolderParams)
    case delete(params: ItemInfoParams)
    case relocate(params: RelocateParams)
    case update(params: UpdateRecordParams)
    
    // UPLOAD
    case getPresignedUrl(params: GetPresignedUrlParams)
    case registerRecord(params: RegisterRecordParams)
    
    // DOWNLOAD
    case getRecord(itemInfo: GetRecordParams)
    case getFolder(itemInfo: GetRecordParams)
    case download(url: URL, filename: String, progressHandler: ProgressHandler?)
    
    // RENAME
    case renameFolder(params: UpdateRecordParams)
    
    //UNSHARE
    case unshareRecord(archiveId: Int, folderLinkId: Int)
    
    case updateRootColumns(params: UpdateRootColumnsParams)
}

extension FilesEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .getRoot:
            return "/folder/getRoot"
        case .getPublicRoot:
            return "/folder/getPublicRoot"
        case .navigateMin:
            return "/folder/navigateMin"
        case .getLeanItems:
            return "/folder/getLeanItems"
        case .getPresignedUrl:
            return "/record/getPresignedUrl"
        case .registerRecord:
            return "/record/registerRecord"
        case .newFolder:
            return "/folder/post"
        case .delete(let parameters):
            if parameters.type.isFolder {
                return "/folder/delete"
            } else {
                return "/record/delete"
            }
            
        case .getRecord:
            return "/record/get"
        case .getFolder:
            return "/folder/get"
        case .relocate(let parameters):
            if parameters.items.source.type.isFolder {
                return "/folder/\(parameters.action.endpointValue)"
            } else {
                return "/record/\(parameters.action.endpointValue)"
            }
            
        case .update:
            return "/record/update"
        case .renameFolder:
            return "/folder/update"
        case .updateRootColumns:
            return "/folder/updateRootColumns"
        case .unshareRecord:
            return "/share/delete"
        default:
            return ""
        }
    }
    
    var method: RequestMethod {
        switch self {
        case .download:
            return .get
            
        default:
            return .post
        }
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .navigateMin(let params):
            return FilesEndpointPayloads.navigateMinPayload(for: params)
            
        case .getLeanItems(let params):
            return FilesEndpointPayloads.getLeanItemsPayload(for: params)
            
        case .getPresignedUrl(let params):
            return FilesEndpointPayloads.getPresignedUrlPayload(for: params)
            
        case .registerRecord(let params):
            return FilesEndpointPayloads.registerRecord(for: params)
            
        case .newFolder(let params):
            return FilesEndpointPayloads.newFolderPayload(for: params)
            
        case .download(_, let filename, _):
            return ["filename": filename]
            
        case .update(let params):
            return FilesEndpointPayloads.updateRecordRequest(params: params)
            
        case .renameFolder(let params):
            return FilesEndpointPayloads.renameFolderRequest(params: params)
            
        case .unshareRecord(let archiveID, let folderLinkId):
            return FilesEndpointPayloads.unshareRecord(archiveId: archiveID, folderLinkId: folderLinkId)
            
        case .updateRootColumns(let params):
            return FilesEndpointPayloads.updateRootColumns(params)
            
        default:
            return nil
        }
    }
    
    var requestType: RequestType {
        switch self {
        case .download:
            return .download
            
        default:
            return .data
        }
    }
    
    var responseType: ResponseType {
        switch self {
        case .download:
            return .file
            
        default:
            return .json
        }
    }
    
    var progressHandler: ProgressHandler? {
        get {
            switch self {
            case .download(_, _, let handler): return handler
            default: return nil
            }
        }
        // swiftlint:disable:next unused_setter_value
        set { }
    }
    
    var bodyData: Data? {
        switch self {
        case .getPublicRoot(let archiveNbr):
            let archiveVO = ArchiveVOPayload(archiveNbr: archiveNbr)
            let requestVO = APIPayload.make(fromData: [archiveVO])
            
            return try? APIPayload<FolderVOPayload>.encoder.encode(requestVO)

        case .delete(let parameters):
            if parameters.type.isFolder {
                let folderVO = FolderVOPayload(folderLinkId: parameters.folderLinkId)
                let requestVO = APIPayload.make(fromData: [folderVO])
                
                return try? APIPayload<FolderVOPayload>.encoder.encode(requestVO)
            } else {
                let recordVO = RecordVOPayload(folderLinkId: parameters.folderLinkId, parentFolderLinkId: parameters.parentFolderLinkId)
                let requestVO = APIPayload.make(fromData: [recordVO])
                
                return try? APIPayload<RecordVOPayload>.encoder.encode(requestVO)
            }
            
        case .getRecord(let itemInfo):
            let recordVO = RecordVOPayload(folderLinkId: itemInfo.folderLinkId, parentFolderLinkId: itemInfo.parentFolderLinkId)
            
            let requestVO = APIPayload.make(fromData: [recordVO])
            
            return try? APIPayload<RecordVOPayload>.encoder.encode(requestVO)
            
        case .getFolder(let itemInfo):
            let folderVO = FolderVOPayload(folderLinkId: itemInfo.folderLinkId)
            
            let requestVO = APIPayload.make(fromData: [folderVO])
            
            return try? APIPayload<FolderVOPayload>.encoder.encode(requestVO)
            
        case .relocate(let parameters):
            if parameters.items.source.type.isFolder {
                let copyVO = RelocateFolderPayload(
                    folderLinkId: parameters.items.source.folderLinkId,
                    folderDestLinkId: parameters.items.destination.folderLinkId
                )
                let requestVO = APIPayload.make(fromData: [copyVO])
                
                return try? APIPayload<RelocateFolderPayload>.encoder.encode(requestVO)
            } else {
                let relocateVO = RelocateRecordPayload(
                    folderLinkId: parameters.items.source.folderLinkId,
                    folderDestLinkId: parameters.items.destination.folderLinkId,
                    parentFolderLinkId: parameters.items.source.parentFolderLinkId,
                    archiveNbr: parameters.items.source.archiveNo,
                    uploadFileName: parameters.items.source.uploadFileName,
                    recordId: parameters.items.source.recordId,
                    parentFolderId: parameters.items.source.parentFolderId
                )
                let requestVO = APIPayload.make(fromData: [relocateVO])
                
                return try? APIPayload<RelocateRecordPayload>.encoder.encode(requestVO)
            }

        default:
            return nil
        }
    }

    var customURL: String? {
        switch self {
        case .download(let url, _, _):
            return url.absoluteString
            
        default:
            return nil
        }
    }
}

class FilesEndpointPayloads {
    static func navigateMinPayload(for params: NavigateMinParams) -> RequestParameters {
        if params.folderLinkId != -1 {
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
        } else {
            return [
                "RequestVO": [
                    "data": [
                        [
                            "FolderVO": [
                                "archiveNbr": params.archiveNo
                            ]
                        ]
                    ]
                ]
            ]
        }
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
