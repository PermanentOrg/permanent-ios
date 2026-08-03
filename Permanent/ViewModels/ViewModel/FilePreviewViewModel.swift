//
//  WebViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.02.2021.
//

import UIKit
import WebKit
import AVKit

enum ImagePreviewState: Equatable {
    case idle
    case loadingThumbnail
    case loadingFullRes(hasThumbnail: Bool)   // S5 when hasThumbnail == false; S8 reuses this after retry
    case loaded
    case failed(hasThumbnail: Bool)           // S6, or the S5 failure variant when no thumbnail exists
    case offline(hasThumbnail: Bool)          // S7
}

class FilePreviewViewModel: ViewModelInterface {
    static let maxRecordFetchAttempts = 3

    let file: FileModel
    var name: String
    var publicURL: URL?

    var recordVO: RecordVO?
    var isEditable: Bool {
        return file.permissions.contains(.edit)
    }

    weak var delegate: FilePreviewNavigationControllerDelegate?

    var downloader: DownloadManagerGCD? = nil

    let tagsRepository: TagsRepository
    let reachability: ReachabilityProviding

    var onImagePreviewStateChanged: ((ImagePreviewState) -> Void)?
    private(set) var imagePreviewState: ImagePreviewState = .idle {
        didSet {
            guard oldValue != imagePreviewState else { return }
            onImagePreviewStateChanged?(imagePreviewState)
        }
    }

    private var recordFetchAttempts = 0

    /// When true (My Files with the Stela flag on), record detail is fetched via the
    /// Stela V2 getRecordById, with the legacy V1 getRecord as an automatic failsafe.
    private let usesStelaDetail: Bool

    /// Extends the V2 record READ to records outside the current archive. Set by the public
    /// gallery, where you browse a FOREIGN archive whose records are public — the same
    /// bearer-only credentials already list that archive's folder children on V2, so there is
    /// no reason the record read should need V1. Read only: writes (patch/copy) stay
    /// own-archive regardless, and the gallery is pinned read-only anyway.
    private let allowsForeignDetail: Bool

    init(file: FileModel, usesStelaDetail: Bool = false, allowsForeignDetail: Bool = false, tagsRepository: TagsRepository = TagsRepository(), reachability: ReachabilityProviding = ReachabilityManager.shared) {
        self.usesStelaDetail = usesStelaDetail
        self.allowsForeignDetail = allowsForeignDetail
        self.tagsRepository = tagsRepository
        self.reachability = reachability
        self.file = file
        name = file.name
    }

    // MARK: - Image preview state transitions

    private var stateHasThumbnail: Bool {
        switch imagePreviewState {
        case .loadingFullRes(let hasThumbnail), .failed(let hasThumbnail), .offline(let hasThumbnail):
            return hasThumbnail
        case .loadingThumbnail, .loaded:
            return true
        case .idle:
            return false
        }
    }

    /// Returns false when offline: the caller should not start any network load.
    @discardableResult
    func startImageLoad(hasThumbnail: Bool) -> Bool {
        guard reachability.isConnected else {
            imagePreviewState = .offline(hasThumbnail: hasThumbnail)
            return false
        }
        imagePreviewState = hasThumbnail ? .loadingThumbnail : .loadingFullRes(hasThumbnail: false)
        return true
    }

    func thumbnailDidLoad() {
        imagePreviewState = .loadingFullRes(hasThumbnail: true)
    }

    func fullResDidLoad() {
        imagePreviewState = .loaded
    }

    func imageLoadDidFail(error: Error?) {
        guard imagePreviewState != .loaded else { return }
        if reachability.isConnected {
            imagePreviewState = .failed(hasThumbnail: stateHasThumbnail)
        } else {
            imagePreviewState = .offline(hasThumbnail: stateHasThumbnail)
        }
    }

    /// The 256px THUMBNAIL failed. Unlike a full-res failure this is not terminal: the
    /// record fetch → full-res load runs in parallel and can still succeed, so while it
    /// is pending we downgrade to the no-thumbnail loading state (S5) instead of painting
    /// the failure card — otherwise a transient thumbnail blip flashes "Couldn't load
    /// image." for the second it takes the full-res to land. The genuine failure/offline
    /// outcome is still reported by the full-res or record-fetch callbacks.
    func thumbnailLoadDidFail(error: Error?) {
        guard imagePreviewState == .loadingThumbnail else { return }
        if reachability.isConnected {
            imagePreviewState = .loadingFullRes(hasThumbnail: false)
        } else {
            imagePreviewState = .offline(hasThumbnail: false)
        }
    }

    /// Returns true when the caller should restart the failed load (S8). While still offline it keeps the offline state and returns false (S7).
    func retryRequested() -> Bool {
        guard reachability.isConnected else {
            imagePreviewState = .offline(hasThumbnail: stateHasThumbnail)
            return false
        }
        recordFetchAttempts = 0
        imagePreviewState = .loadingFullRes(hasThumbnail: stateHasThumbnail)
        return true
    }

    /// Returns true when the caller should resume loading after connectivity came back while in the offline state.
    func connectivityRestored() -> Bool {
        guard case .offline = imagePreviewState, reachability.isConnected else { return false }
        return retryRequested()
    }

    // MARK: - Record fetching

    func getRecord(file: FileModel, then handler: @escaping (RecordVO?) -> Void) {
        #if DEBUG
        // QA hook: launch with `--failRecordLoad` to simulate a failed record fetch
        // (e.g. a real-device offline open), exercising the failure/offline preview card.
        if CommandLine.arguments.contains("--failRecordLoad") {
            handler(nil)
            return
        }
        #endif

        // Stela V2 detail with the legacy V1 fetch as an automatic failsafe. Own-archive
        // records on any screen, plus foreign records where the caller says the read is
        // public (`allowsForeignDetail` — the gallery). Shared-with-me records still go to
        // V1: those are authorized server-side via share membership, which the bearer-only
        // V2 read can't carry. The failsafe makes a wrong guess cheap — a rejected V2 read
        // silently becomes the V1 read, costing one request, because record reads are
        // idempotent (unlike copy, which is why copy has no fallback).
        if usesStelaDetail, file.recordId > 0, isInCurrentArchive(file) || allowsForeignDetail {
            getRecordV2(file: file, then: handler)
            return
        }
        getRecordV1(file: file, then: handler)
    }

    private func getRecordV1(file: FileModel, then handler: @escaping (RecordVO?) -> Void) {
        let downloadInfo = FileDownloadInfoVM(
            fileType: file.type,
            folderLinkId: file.folderLinkId,
            parentFolderLinkId: file.parentFolderLinkId
        )

        downloader = DownloadManagerGCD()
        downloader?.getRecord(downloadInfo) { [weak self] (record, error) in
            self?.onRecordCallback(file: file, record: record, error: error, then: handler)
        }
    }

    /// Fetches the record via Stela GET /api/v2/records/{id}, maps it into the legacy
    /// `RecordVO` (so all detail/preview/download consumers are unchanged), and falls
    /// back to the V1 fetch on any error, decode failure, or a payload that lacks a
    /// usable file (download URL + contentType — `loadRecord()` requires BOTH, so a
    /// thin V2 response never degrades the preview to a blank screen).
    private func getRecordV2(file: FileModel, then handler: @escaping (RecordVO?) -> Void) {
        let operation = APIOperation(RecordV2Endpoint.getRecordById(recordId: String(file.recordId), shareToken: ""))
        operation.execute(in: APIRequestDispatcher()) { [weak self] result in
            guard let self = self else { handler(nil); return }
            switch result {
            case .json(let response, _):
                guard
                    let model: RecordV2Response = JSONHelper.decoding(from: response, with: RecordV2Response.decoder),
                    let data = model.data,
                    let recordVO: RecordVO = JSONHelper.decoding(from: data.toRecordVOPayload(), with: RecordVO.decoder),
                    recordVO.recordVO?.fileVOS?.contains(where: { ($0.downloadURL?.isEmpty == false) && ($0.contentType?.isEmpty == false) }) == true
                else {
                    self.getRecordV1(file: file, then: handler) // failsafe
                    return
                }
                self.recordFetchAttempts = 0
                self.recordVO = recordVO
                handler(recordVO)

            default:
                self.getRecordV1(file: file, then: handler) // failsafe
            }
        }
    }

    func onRecordCallback(file: FileModel, record: RecordVO?, error: Error?, then handler: @escaping (RecordVO?) -> Void) {
        if record != nil && error == nil {
            recordFetchAttempts = 0
            recordVO = record

            handler(record)
        } else {
            recordFetchAttempts += 1
            guard recordFetchAttempts < Self.maxRecordFetchAttempts, reachability.isConnected else {
                recordFetchAttempts = 0
                handler(nil)
                return
            }
            getRecord(file: file, then: handler)
        }
    }
    
    /// Whether this preview opted into the Stela V2 path (the in-app flag; set on every
    /// preview presenter — per-record ownership is checked separately, see below).
    var isStelaEnabled: Bool { usesStelaDetail }

    /// True when the record belongs to the user's currently selected archive. Foreign/
    /// shared records (Shares, public archive, share-link) carry a different or absent
    /// (-1) archiveId and must stay on V1, whose bearer-token + server-side share
    /// membership authorizes them; indeterminate ownership falls to V1.
    private func isInCurrentArchive(_ file: FileModel) -> Bool {
        guard let currentArchiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID else { return false }
        return file.archiveId > 0 && file.archiveId == currentArchiveId
    }

    /// Publish eligibility for the V2 copy route: flag on, a saved record (not a folder),
    /// and owned by the current archive — foreign/shared records must publish via the V1
    /// relocate, since the bearer-only V2 copy would be rejected and copy has NO V1
    /// fallback (it is not idempotent).
    var canPublishViaStelaCopy: Bool {
        isStelaEnabled && !file.type.isFolder && file.recordId > 0 && isInCurrentArchive(file)
    }

    /// Publishes/copies the record into `destinationFolderId` via Stela
    /// POST /records/{id}/copies. Copy is NOT idempotent, so this is flag-SELECT:
    /// callers invoke it only when `isStelaEnabled`, and must NOT fall back to V1 on
    /// error (a mis-read success would otherwise create a duplicate copy).
    func copyRecordV2(destinationFolderId: String, completion: @escaping (Error?) -> Void) {
        let apiOperation = APIOperation(RecordV2Endpoint.copyRecord(recordId: String(file.recordId), destinationFolderId: destinationFolderId))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            DispatchQueue.main.async {
                switch result {
                case .json:
                    completion(nil)
                case .error(let error, _):
                    completion(error ?? APIError.unknown)
                default:
                    completion(APIError.unknown)
                }
            }
        }
    }

    // Test seams for resolvePublicRootFolderIdV2 (mirror MyFilesViewModel's archives/children
    // seams). NOTE: the two fetch wrappers below duplicate MyFilesViewModel's — a candidate
    // for consolidation into a shared Stela-root resolver once both paths are committed.
    var archivesFetchV2Request: ((@escaping (Result<[ArchiveV2Data], Error>) -> Void) -> Void)?
    var rootChildrenFetchV2Request: ((String, @escaping (Result<[FolderChildV2Data], Error>) -> Void) -> Void)?

    /// Resolves the current archive's PUBLIC-root folder id via the Stela archives search —
    /// the VSP-1787 sibling of My Files root discovery: GET /api/v2/archives → match by
    /// `archiveNbr` → `rootFolderId` → its `type.folder.root.public` child. Returns nil on
    /// ANY failure (no archive, network error, archive not listed, missing/empty rootFolderId,
    /// no public-root child, bad id) so publish falls back to the V1 `getPublicRoot`
    /// destination lookup. The returned id feeds `copyRecordV2`'s `destinationFolderId`.
    func resolvePublicRootFolderIdV2(completion: @escaping (String?) -> Void) {
        guard let archiveNbr = AuthenticationManager.shared.session?.selectedArchive?.archiveNbr, !archiveNbr.isEmpty else {
            completion(nil)
            return
        }
        fetchArchivesV2 { [weak self] result in
            guard let self = self else { completion(nil); return }
            guard
                case .success(let archives) = result,
                let rootFolderId = archives.first(where: { $0.archiveNbr == archiveNbr })?.rootFolderId,
                !rootFolderId.isEmpty
            else {
                completion(nil)
                return
            }
            self.fetchRootChildrenV2(folderId: rootFolderId) { childrenResult in
                guard
                    case .success(let children) = childrenResult,
                    let publicChild = children.first(where: {
                        $0.isFolder && FileType.fromV2(typeString: $0.type, isFolder: true) == .publicRootFolder
                    }),
                    let folderId = publicChild.folderId, !folderId.isEmpty, (Int(folderId) ?? -1) > 0
                else {
                    completion(nil)
                    return
                }
                completion(folderId)
            }
        }
    }

    private func fetchArchivesV2(completion: @escaping (Result<[ArchiveV2Data], Error>) -> Void) {
        if let injected = archivesFetchV2Request {
            injected(completion)
            return
        }
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

    private func fetchRootChildrenV2(folderId: String, completion: @escaping (Result<[FolderChildV2Data], Error>) -> Void) {
        if let injected = rootChildrenFetchV2Request {
            injected(folderId, completion)
            return
        }
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

    func download(_ record: RecordVO, fileType: FileType, onFileDownloaded: @escaping DownloadResponse) {
        downloader = DownloadManagerGCD()
        downloader?.downloadFileData(record: record, fileType: fileType, progressHandler: nil, then: onFileDownloaded)
    }
    
    func fileData(withURL url: URL, onCompletion completion: @escaping (Data?, Error?) -> Void) {
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        dataTask.resume()
    }
    
    func cancelDownload() {
        downloader?.cancelDownload()
        downloader = nil
    }
    
    func fileVO() -> FileVO? {
        // For A/V, prefer the app-friendly converted rendition, else the first file — matching
        // DownloadManagerGCD.fileVO. Previously this probed `AVAsset(url:).isPlayable`
        // synchronously on a REMOTE url, which blocks the main thread (fileVO() is called on
        // main from loadRecord); AVPlayer already surfaces unplayable assets at play time.
        if file.type == .video || file.type == .audio,
           let converted = recordVO?.recordVO?.fileVOS?.first(where: { $0.format == "file.format.converted" }) {
            return converted
        }

        return recordVO?.recordVO?.fileVOS?.first
    }
    
    /// The Archivematica-generated PDF rendition of this record, when it has one.
    ///
    /// Document types (spreadsheets, presentations, …) cannot be rendered inline by the
    /// preview's web view: WebKit refuses the original's MIME type and turns the navigation
    /// into a download, so nothing is ever displayed. This access copy is a real PDF that
    /// PDFKit renders directly.
    ///
    /// Preview only, deliberately separate from `fileVO()` — that stays on the original so
    /// Download and `fileName()` keep giving the user the file they actually uploaded.
    func pdfAccessCopyURL() -> URL? {
        guard let accessCopy = recordVO?.recordVO?.fileVOS?.first(where: {
            $0.type == "type.file.pdf.pdf" && $0.format == "file.format.archivematica.access"
        }) else { return nil }

        // fileURL is the plain object; downloadURL carries a content-disposition that would
        // ask for a save instead of a render.
        guard let urlString = accessCopy.fileURL ?? accessCopy.downloadURL else { return nil }
        return URL(string: urlString)
    }

    func fileThumbnailURL() -> String? {
        let stringURL: String? = recordVO?.recordVO?.preferredThumbnailURL
        return stringURL
    }
    
    func fileName() -> String? {
        guard let fileVO = self.fileVO(),
              let uploadFileName = self.recordVO?.recordVO?.uploadFileName,
              let displayName = self.recordVO?.recordVO?.displayName
        else {
            return ""
        }
        
        // If the file was converted, then it most certainly is an mp4
        // Otherwise, the file was not converted, we use the original filename + extension
        let fileName: String
        if self.file.type == .video && fileVO.contentType == "video/mp4" {
            fileName = displayName + ".mp4"
        } else {
            fileName = uploadFileName
        }
        return fileName
    } 
    
    func update(file: FileModel, name: String?, description: String?, date: Date?, location: LocnVO?, completion: @escaping ((Bool) -> Void)) {
        // Stela V2 PATCH handles name / description / location edits — all idempotent
        // (the server updates the record's fields, and its existing location row in place).
        // DATE stays on V1: the record PATCH exposes only the EDTF `displayTime` column,
        // not the `displaydt` timestamp the "Date" row displays, so a V2 date edit would
        // not reflect. The V1 failsafe covers any V2 miss. Own-archive records only —
        // same scoping as the read path: a foreign/shared record's bearer-only PATCH
        // would just burn a doomed round-trip before the V1 failsafe re-applies.
        if usesStelaDetail, file.recordId > 0, isInCurrentArchive(file), date == nil, (name != nil || description != nil || location != nil) {
            updateV2(file: file, name: name, description: description, location: location, completion: completion)
            return
        }
        updateV1(file: file, name: name, description: description, date: date, location: location, completion: completion)
    }

    private func updateV2(file: FileModel, name: String?, description: String?, location: LocnVO?, completion: @escaping ((Bool) -> Void)) {
        var fields: [String: Any] = [:]
        if let name = name { fields["displayName"] = name }
        if let description = description { fields["description"] = description }
        if let location = location {
            let payload = location.toLocationInputPayload()
            if !payload.isEmpty { fields["location"] = payload }
        }
        guard !fields.isEmpty else {
            updateV1(file: file, name: name, description: description, date: nil, location: location, completion: completion)
            return
        }
        let apiOperation = APIOperation(RecordV2Endpoint.patchRecord(recordId: String(file.recordId), fields: fields))
        apiOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { completion(false); return }
                switch result {
                case .json:
                    self.getRecord(file: file) { _ in
                        NotificationCenter.default.post(name: .filePreviewVMDidSaveData, object: self)
                        completion(true)
                    }
                default:
                    // Failsafe — re-apply the edit via V1 (idempotent).
                    self.updateV1(file: file, name: name, description: description, date: nil, location: location, completion: completion)
                }
            }
        }
    }

    private func updateV1(file: FileModel, name: String?, description: String?, date: Date?, location: LocnVO?, completion: @escaping ((Bool) -> Void)) {
        let params: UpdateRecordParams = (name, description, date, location, file.recordId, file.folderLinkId, file.archiveNo)
        let apiOperation = APIOperation(FilesEndpoint.update(params: params))

        apiOperation.execute(in: APIRequestDispatcher()) { result in
            DispatchQueue.main.async {
                switch result {
                case .json( _, _):
                    self.getRecord(file: file) { (record) in
                        NotificationCenter.default.post(name: .filePreviewVMDidSaveData, object: self)
                        completion(true)
                    }

                case .error(_, _):
                    NotificationCenter.default.post(name: .filePreviewVMSaveDataFailed, object: self)
                    completion(false)

                default:
                    NotificationCenter.default.post(name: .filePreviewVMSaveDataFailed, object: self)
                    completion(false)
                }
            }
        }
    }
    
    func validateLocation(lat: Double, long: Double, completion: @escaping ((LocnVO?) -> Void)) {
        let params: GeomapLatLongParams = (lat, long)
        let apiOperation = APIOperation(LocationEndpoint.geomapLatLong(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let json, _):
                guard let model: APIResults<LocnVOData> = JSONHelper.decoding(from: json, with: APIResults<LocnVOData>.decoder), model.isSuccessful else {
                    completion(nil)
                    return
                }
                let locnVO: LocnVO? = model.results.first?.data?.first?.locnVO
                completion(locnVO)
                
            case .error(_, _):
                completion(nil)
                
            default:
                completion(nil)
            }
        }
    }
    
    func getAddressString(_ items: [String?], _ inMetadataScreen: Bool = true) -> String {
        var address = items.compactMap { $0 }.joined(separator: ", ")
        if inMetadataScreen && isEditable {
            address == "" ? (address = "Tap to set".localized()) : ()
        }
        return address
    }
    
    func getTagsByArchive(archiveId: Int, completion: @escaping (([TagVO]?) -> Void)) {
        let tags = tagsRepository.getTagsByArchive(archiveId: archiveId) { tags, error in
            if let tags = tags {
                completion(tags)
            } else {
                completion(nil)
            }
        }
        completion(tags)
    }
    
    func addTag(tagNames: [String], completion: @escaping (([TagLinkVO]?) -> Void)) {
        tagsRepository.assignTag(tagNames: tagNames, recordId: recordVO?.recordVO?.recordID ?? 0) { tags, error in
            if let tags = tags {
                self.getRecord(file: self.file) { (record) in
                    completion(tags)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    func unassignTag(tagVO: [TagVO], completion: @escaping ((String?) -> Void)) {
        tagsRepository.unassignTag(tagVO: tagVO, recordId: recordVO?.recordVO?.recordID ?? 0) { error in
            if error == nil {
                self.getRecord(file: self.file) { (record) in
                    completion(nil)
                }
            } else {
                completion(error.debugDescription)
            }
        }
    }
    
    func deleteTag(tagVO: [TagVO], completion: @escaping ((String?) -> Void)) {
        tagsRepository.deleteTag(tagVO: tagVO) { error in
            if error == nil {
                self.getRecord(file: self.file) { (record) in
                    completion(nil)
                }
            } else {
                completion(error.debugDescription)
            }
        }
    }
}
