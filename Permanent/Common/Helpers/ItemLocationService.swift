//
//  ItemLocationService.swift
//  Permanent
//
//  Created by Lucian Cerbu on 19.10.2026.
//

import Foundation
import os

/// Reads and saves the location of records and folders through Stela V2. A failed save answers false,
/// and the screen that asked runs its own V1 failsafe.
struct ItemLocationService {
    typealias Patch = (_ file: FileModel, _ fields: [String: Any], _ completion: @escaping (Bool) -> Void) -> Void
    typealias FetchFolder = (_ folderId: String, _ completion: @escaping (OperationResult) -> Void) -> Void

    static let logger = Logger(subsystem: "com.permanent.ios", category: "ItemLocation")

    var patchRecord: Patch = { file, fields, completion in
        Self.send(RecordV2Endpoint.patchRecord(recordId: String(file.recordId), fields: fields), completion: completion)
    }
    var patchFolder: Patch = { file, fields, completion in
        Self.send(FolderV2Endpoint.patchFolder(folderId: String(file.folderId), fields: fields), completion: completion)
    }
    var fetchFolder: FetchFolder = { folderId, completion in
        let operation = APIOperation(FolderV2Endpoint.getFolderById(folderId: folderId, shareToken: ""))
        operation.execute(in: APIRequestDispatcher()) { completion($0) }
    }

    /// Saves `location` on every item, one PATCH at a time and in order. True only when every PATCH succeeded.
    func save(_ location: LocnVO, to files: [FileModel], completion: @escaping (Bool) -> Void) {
        let payload = location.toLocationInputPayload()
        guard !payload.isEmpty, !files.isEmpty, files.allSatisfy(Self.hasStelaId) else {
            completion(false)
            return
        }
        let patchRecord = patchRecord
        let patchFolder = patchFolder
        [FileModel].patchSequentially(files: files, fieldsFor: { _ in ["location": payload] }, patchOne: { file, fields, done in
            if file.type.isFolder {
                patchFolder(file, fields, done)
            } else {
                patchRecord(file, fields, done)
            }
        }, completion: completion)
    }

    /// The folder's location as Stela V2 sends it, on the main queue. Nil when the folder has none or the read fails.
    func folderLocation(folderId: Int, completion: @escaping (LocnVO?) -> Void) {
        fetchFolder(String(folderId)) { result in
            var location: LocnVO?
            if case .json(let response, _) = result,
               let model: FolderV2Response = JSONHelper.decoding(from: response, with: FolderV2Response.decoder),
               let payload = model.items?.first?.location?.toLocnVOPayload() {
                location = JSONHelper.decoding(from: payload, with: LocnVO.decoder)
            }
            DispatchQueue.main.async { completion(location) }
        }
    }

    private static func hasStelaId(_ file: FileModel) -> Bool {
        file.type.isFolder ? file.folderId > 0 : file.recordId > 0
    }

    private static func send(_ endpoint: RequestProtocol, completion: @escaping (Bool) -> Void) {
        let operation = APIOperation(endpoint)
        operation.execute(in: APIRequestDispatcher()) { result in
            if case .json = result {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
}
