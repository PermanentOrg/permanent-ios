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

    init(file: FileModel, usesStelaDetail: Bool = false, tagsRepository: TagsRepository = TagsRepository(), reachability: ReachabilityProviding = ReachabilityManager.shared) {
        self.usesStelaDetail = usesStelaDetail
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

        // Stela V2 detail (My Files only) with the legacy V1 fetch as an automatic failsafe.
        if usesStelaDetail, file.recordId > 0 {
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
    /// usable file download URL — so a thin V2 response never degrades the preview.
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
                    recordVO.recordVO?.fileVOS?.contains(where: { ($0.downloadURL?.isEmpty == false) }) == true
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
    
    /// Whether this preview opted into the Stela V2 path (My Files + flag on).
    var isStelaEnabled: Bool { usesStelaDetail }

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
        var fileVO: FileVO? = recordVO?.recordVO?.fileVOS?.first

        if file.type == .video || file.type == .audio {
            if let uwFileVO = recordVO?.recordVO?.fileVOS?.first,
               let url = URL(string: uwFileVO.downloadURL),
               AVAsset(url: url).isPlayable {
                fileVO = uwFileVO
            } else if let uwFileVO = recordVO?.recordVO?.fileVOS?.first(where: {$0.format == "file.format.converted"}) {
                fileVO = uwFileVO
            }
        }
        
        return fileVO
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
        // not reflect. The V1 failsafe covers any V2 miss. Gated to My Files via usesStelaDetail.
        if usesStelaDetail, file.recordId > 0, date == nil, (name != nil || description != nil || location != nil) {
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
