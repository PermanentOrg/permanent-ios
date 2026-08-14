//
//  RecordV2Endpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.02.2026.
//

import Foundation

enum RecordV2Endpoint {
    case getRecordById(recordId: String, shareToken: String?)
    /// A flat body of only the edited fields. The server rejects unknown keys, so never include
    /// recordId, archiveNbr or folder_linkId.
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

    /// `true` suppresses the 401 force-logout. Reads are exempt, since a foreign record legitimately
    /// 401s; writes are not, because a 401 there really is an expired session.
    var ignoreErrors: Bool {
        switch self {
        case .getRecordById: return true
        case .patchRecord, .copyRecord: return false
        }
    }
}

extension Array where Element == FileModel {
    /// PATCHes each record serially, sending only the fields `fieldsFor` returns. `true` only if every
    /// one succeeded. Each PATCH sets absolute values, so a V1 re-apply rewrites rather than doubles.
    func patchEachRecordToV2(fieldsFor: @escaping (FileModel) -> [String: Any],
                             completion: @escaping (Bool) -> Void) {
        Array<FileModel>.patchSequentially(files: self, fieldsFor: fieldsFor, patchOne: { file, fields, done in
            let operation = APIOperation(RecordV2Endpoint.patchRecord(recordId: String(file.recordId), fields: fields))
            operation.execute(in: APIRequestDispatcher()) { result in
                if case .json = result {
                    done(true)
                } else {
                    done(false)
                }
            }
        }, completion: completion)
    }

    /// The aggregation core with the network call injectable, so the contract is testable: serial and
    /// in order, `true` only on total success. `true` on partial success would drop the rest silently.
    static func patchSequentially(files: [FileModel],
                                  fieldsFor: @escaping (FileModel) -> [String: Any],
                                  patchOne: @escaping (FileModel, [String: Any], @escaping (Bool) -> Void) -> Void,
                                  completion: @escaping (Bool) -> Void) {
        Task {
            var allSucceeded = true
            for file in files {
                let succeeded: Bool = await withCheckedContinuation { continuation in
                    patchOne(file, fieldsFor(file)) { continuation.resume(returning: $0) }
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
