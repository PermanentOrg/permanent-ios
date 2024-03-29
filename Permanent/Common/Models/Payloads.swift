//
//  Payloads.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23/09/2020.
//

import Foundation
import UIKit

struct Payloads {
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
}
