//
//  RecordV2Endpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.02.2026.
//

import Foundation

enum RecordV2Endpoint {
    case getRecordById(recordId: String, shareToken: String?)
    /// PATCH /api/v2/records/{id} with a FLAT body of only the edited fields
    /// (e.g. ["displayName": x] / ["description": y]). The server rejects unknown
    /// keys, so never include recordId/archiveNbr/folder_linkId in the body.
    case patchRecord(recordId: String, fields: [String: Any])
    /// POST /api/v2/records/{id}/copies — copies the record into `destinationFolderId`.
    /// `ip` and auth are injected server-side, so the body carries only the destination.
    case copyRecord(recordId: String, destinationFolderId: String)
}

extension RecordV2Endpoint: RequestProtocol {
    var path: String { "" }  // Not used - we use customURL

    var method: RequestMethod {
        switch self {
        case .getRecordById: return .get
        case .patchRecord: return .patch
        case .copyRecord: return .post
        }
    }

    var requestType: RequestType { .data }

    var responseType: ResponseType { .json }

    var parameters: RequestParameters? { nil }

    var progressHandler: ProgressHandler? {
        get { nil }
        set { }
    }

    var bodyData: Data? {
        switch self {
        case .getRecordById:
            return nil
        case .patchRecord(_, let fields):
            return try? JSONSerialization.data(withJSONObject: fields)
        case .copyRecord(_, let destinationFolderId):
            return try? JSONSerialization.data(withJSONObject: ["destinationFolderId": destinationFolderId])
        }
    }

    var customURL: String? {
        let baseURL = APIEnvironment.defaultEnv.apiServer
        switch self {
        case .getRecordById(let recordId, _):
            return "\(baseURL)api/v2/records/\(recordId)"
        case .patchRecord(let recordId, _):
            return "\(baseURL)api/v2/records/\(recordId)"
        case .copyRecord(let recordId, _):
            return "\(baseURL)api/v2/records/\(recordId)/copies"
        }
    }

    var shareToken: String? {
        switch self {
        case .getRecordById(_, let token):
            guard let token, !token.isEmpty else { return nil }
            return token
        case .patchRecord, .copyRecord:
            return nil
        }
    }
    
    var headers: RequestHeaders? {
        return ["Content-Type": "application/json", "Request-Version": "2"]
    }
    
    var ignoreErrors: Bool { false }
}

extension Array where Element == FileModel {
    /// Serially PATCHes each record to Stela V2 — one `RecordV2Endpoint.patchRecord` call
    /// per record, sending only the fields returned by `fieldsFor`. Calls back `true` ONLY
    /// if every record succeeded; short-circuits on the first failure and calls back `false`
    /// so the caller can fall back to the V1 batch. Completion is delivered on the main
    /// actor. Each PATCH sets absolute values (name/description/location) and is therefore
    /// idempotent, so a V1 batch re-apply after a partial V2 success re-writes the same
    /// target values rather than double-applying.
    func patchEachRecordToV2(fieldsFor: @escaping (FileModel) -> [String: Any],
                             completion: @escaping (Bool) -> Void) {
        Task {
            var allSucceeded = true
            for file in self {
                let succeeded: Bool = await withCheckedContinuation { continuation in
                    let operation = APIOperation(RecordV2Endpoint.patchRecord(recordId: String(file.recordId), fields: fieldsFor(file)))
                    operation.execute(in: APIRequestDispatcher()) { result in
                        if case .json = result {
                            continuation.resume(returning: true)
                        } else {
                            continuation.resume(returning: false)
                        }
                    }
                }
                if !succeeded {
                    allSucceeded = false
                    break
                }
            }
            let didSucceed = allSucceeded
            await MainActor.run { completion(didSucceed) }
        }
    }
}
