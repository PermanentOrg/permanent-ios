//
//  FolderInfo.swift
//  Permanent
//
//  Created by Adrian Creteanu on 03/11/2020.
//

import Foundation

class FolderInfo: NSObject, NSCoding {
    let folderId: Int
    let folderLinkId: Int

    /// Display name of the folder, used by the upload Live Activity's folder card.
    /// Optional because most call sites don't need it and older persisted upload
    /// queues were encoded without it.
    let name: String?
    /// How many items the folder held when the upload was queued. The Live Activity
    /// adds each completed file on top of this to show a live count.
    let itemCount: Int?
    /// Whether the folder lives in the Shared workspace rather than Private. Drives
    /// the badge on the Live Activity's folder card.
    let isShared: Bool?

    /// The extra fields default to `nil` so the call sites that only navigate by id
    /// stay unchanged; only the upload entry points populate them.
    init(folderId: Int, folderLinkId: Int, name: String? = nil, itemCount: Int? = nil, isShared: Bool? = nil) {
        self.folderId = folderId
        self.folderLinkId = folderLinkId
        self.name = name
        self.itemCount = itemCount
        self.isShared = isShared
    }

    func encode(with coder: NSCoder) {
        coder.encode(folderId, forKey: "folderId")
        coder.encode(folderLinkId, forKey: "folderLinkId")
        coder.encode(name, forKey: "name")
        coder.encode(itemCount, forKey: "itemCount")
        coder.encode(isShared, forKey: "isShared")
    }

    required init?(coder: NSCoder) {
        self.folderId = coder.decodeInteger(forKey: "folderId")
        self.folderLinkId = coder.decodeInteger(forKey: "folderLinkId")
        // `decodeObject` rather than `decodeInteger`/`decodeBool`, so an upload
        // queue persisted by an older build decodes to nil instead of 0/false.
        self.name = coder.decodeObject(forKey: "name") as? String
        self.itemCount = coder.decodeObject(forKey: "itemCount") as? Int
        self.isShared = coder.decodeObject(forKey: "isShared") as? Bool
    }
}
