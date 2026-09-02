//
//  SectionRootResolverV2.swift
//  Permanent
//

import Foundation

/// Resolves an archive section root (private-root, public-root) from Stela reads only: the archive's
/// `rootFolderId` from the archives search, then the child whose `type` matches. Nil on any failure.
/// The display-name fallback is for navigation; a write destination passes nil and matches by type only.
final class SectionRootResolverV2 {
    typealias ArchivesFetch = (@escaping (Result<[ArchiveV2Data], Error>) -> Void) -> Void
    typealias ChildrenFetch = (String, @escaping (Result<[FolderChildV2Data], Error>) -> Void) -> Void

    private let fetchArchives: ArchivesFetch
    private let fetchChildren: ChildrenFetch

    /// Pass the two fetches to run without the network; nil uses the live endpoints.
    init(fetchArchives: ArchivesFetch? = nil, fetchChildren: ChildrenFetch? = nil) {
        self.fetchArchives = fetchArchives ?? Self.liveArchivesFetch
        self.fetchChildren = fetchChildren ?? Self.liveChildrenFetch
    }

    func resolve(sectionType: FileType, fallbackDisplayName: String?, archiveNbr: String?, completion: @escaping (FolderChildV2Data?) -> Void) {
        guard let archiveNbr = archiveNbr, !archiveNbr.isEmpty else {
            completion(nil)
            return
        }
        fetchArchives { [fetchChildren] result in
            guard
                case .success(let archives) = result,
                let rootFolderId = archives.first(where: { $0.archiveNbr == archiveNbr })?.rootFolderId,
                !rootFolderId.isEmpty
            else {
                completion(nil)
                return
            }
            fetchChildren(rootFolderId) { childrenResult in
                guard case .success(let children) = childrenResult else {
                    completion(nil)
                    return
                }
                completion(Self.sectionRootChild(in: children, sectionType: sectionType, fallbackDisplayName: fallbackDisplayName))
            }
        }
    }

    /// Picks a section-root child among an archive root's children, matching the Stela `type` first
    /// and the display name second — a safety net until every environment's `type` is confirmed.
    static func sectionRootChild(in children: [FolderChildV2Data], sectionType: FileType, fallbackDisplayName: String?) -> FolderChildV2Data? {
        if let byType = children.first(where: {
            $0.isFolder && FileType.fromV2(typeString: $0.type, isFolder: true) == sectionType
        }) {
            return byType
        }
        guard let fallbackDisplayName = fallbackDisplayName else { return nil }
        return children.first(where: {
            $0.isFolder && $0.displayName == fallbackDisplayName
        })
    }

    // MARK: - Live fetches

    private static func liveArchivesFetch(completion: @escaping (Result<[ArchiveV2Data], Error>) -> Void) {
        let endpoint = ArchiveV2Endpoint.searchArchives(
            callerMembershipRoles: ArchiveV2Endpoint.allMembershipRoles,
            pageSize: ArchiveV2Endpoint.defaultPageSize
        )
        APIOperation(endpoint).execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: ArchivesV2Response = JSONHelper.decoding(from: response, with: ArchivesV2Response.decoder),
                    let items = model.items
                else {
                    completion(.failure(APIError.parseError))
                    return
                }
                completion(.success(items))
            case .error(let error, _):
                completion(.failure(error ?? APIError.unknown))
            default:
                completion(.failure(APIError.unknown))
            }
        }
    }

    private static func liveChildrenFetch(folderId: String, completion: @escaping (Result<[FolderChildV2Data], Error>) -> Void) {
        let endpoint = FolderV2Endpoint.getFolderChildren(folderId: folderId, shareToken: "", pageSize: FolderV2Endpoint.maxChildrenPageSize)
        APIOperation(endpoint).execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: FolderChildrenV2Response = JSONHelper.decoding(from: response, with: FolderChildrenV2Response.decoder),
                    let items = model.items
                else {
                    completion(.failure(APIError.parseError))
                    return
                }
                completion(.success(items))
            case .error(let error, _):
                completion(.failure(error ?? APIError.unknown))
            default:
                completion(.failure(APIError.unknown))
            }
        }
    }
}
