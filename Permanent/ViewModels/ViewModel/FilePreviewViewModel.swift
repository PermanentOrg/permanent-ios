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

    /// Extends the V2 record read to foreign archives, for the public gallery — the same bearer-only
    /// credentials already list that archive's children. Reads only; writes stay own-archive.
    private let allowsForeignDetail: Bool

    init(file: FileModel, allowsForeignDetail: Bool = false, tagsRepository: TagsRepository = TagsRepository(), reachability: ReachabilityProviding = ReachabilityManager.shared) {
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

    /// A thumbnail failure is not terminal — the full-res load runs in parallel — so downgrade to the
    /// no-thumbnail loading state rather than flash a failure card. The full-res reports the truth.
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

        // V2 detail with V1 as an automatic failsafe: own-archive records, plus foreign ones the caller
        // says are public. Shared-with-me stays on V1, authorized server-side via share membership.
        if file.recordId > 0, isInCurrentArchive(file) || allowsForeignDetail {
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

    /// Fetches the record via V2 and maps it into the legacy `RecordVO`, so consumers are unchanged.
    /// Falls back to V1 on any error or a payload thin enough to blank the preview.
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
    
    /// True when the record is in the session's selected archive. A foreign or shared record carries
    /// a different or absent archiveId and stays on V1; unknown ownership also falls to V1.
    private func isInCurrentArchive(_ file: FileModel) -> Bool {
        guard let currentArchiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID else { return false }
        return file.archiveId > 0 && file.archiveId == currentArchiveId
    }

    /// Publish eligibility for the V2 copy: a saved record in the own archive. A foreign record
    /// must use the V1 relocate, since copy has no fallback and the bearer-only call would fail.
    var canPublishViaStelaCopy: Bool {
        !file.type.isFolder && file.recordId > 0 && isInCurrentArchive(file)
    }

    /// Copies the record into `destinationFolderId` via V2. Copy is not idempotent, so callers must
    /// not fall back to V1 on error — a mis-read success would duplicate the copy.
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

    // Test seams for `resolvePublicRootFolderIdV2`.
    var archivesFetchV2Request: ((@escaping (Result<[ArchiveV2Data], Error>) -> Void) -> Void)?
    var rootChildrenFetchV2Request: ((String, @escaping (Result<[FolderChildV2Data], Error>) -> Void) -> Void)?

    /// Resolves the archive's public-root folder id through the archives search, matching by
    /// `archiveNbr`. Nil on any failure, so publish falls back to the V1 `getPublicRoot` lookup.
    func resolvePublicRootFolderIdV2(completion: @escaping (String?) -> Void) {
        let resolver = SectionRootResolverV2(fetchArchives: archivesFetchV2Request, fetchChildren: rootChildrenFetchV2Request)
        let archiveNbr = AuthenticationManager.shared.session?.selectedArchive?.archiveNbr
        resolver.resolve(sectionType: .publicRootFolder, fallbackDisplayName: nil, archiveNbr: archiveNbr) { publicChild in
            guard let folderId = publicChild?.folderId, !folderId.isEmpty, (Int(folderId) ?? -1) > 0 else {
                completion(nil)
                return
            }
            completion(folderId)
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
    
    /// Always the original upload: the normalised derivative may carry no playable audio track, and
    /// probing which to use blocks main. An unplayable original retries via `convertedAVFileVO()`.
    func fileVO() -> FileVO? {
        recordVO?.recordVO?.fileVOS?.first
    }

    /// The converted A/V rendition, used only as the fallback when the original fails to load.
    /// Nil when the record has no such rendition, in which case the failure is terminal.
    func convertedAVFileVO() -> FileVO? {
        guard file.type == .video || file.type == .audio else { return nil }
        return recordVO?.recordVO?.fileVOS?.first(where: { $0.format == "file.format.converted" })
    }
    
    /// The PDF rendition, for document types WebKit refuses to render inline and turns into a
    /// download. Preview only: `fileVO()` stays on the original, so Download gives the real file.
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
        // V2 PATCH covers name, description and location, which are idempotent. Date stays on V1: the
        // PATCH exposes only the EDTF column, not the timestamp the Date row shows. Own archive only.
        if file.recordId > 0, isInCurrentArchive(file), date == nil, (name != nil || description != nil || location != nil) {
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
