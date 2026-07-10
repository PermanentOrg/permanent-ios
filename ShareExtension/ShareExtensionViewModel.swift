//
//  ShareExtensionViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.07.2022.
//

import Foundation
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

typealias ShareExtensionCellConfiguration = (fileImage: UIImage?, fileName: String?, fileSize: String?)

enum StorageQuotaError: Error {
    case insufficientSpace
    case apiError
    
    var localizedDescription: String {
        switch self {
        case .insufficientSpace:
            return "Not enough storage space available. Please free up space or upgrade your storage plan."
        case .apiError:
            return "Unable to check storage space. Please try again."
        }
    }
}

class ShareExtensionViewModel: ViewModelInterface {
    var currentArchive: ArchiveVOData? {
        return PermSession.currentSession?.selectedArchive
    }
    var session: PermSession? {
        return PermSession.currentSession
    }
    
    var selectedFiles: [FileInfo] = []
    var parentFolder: FolderInfo?
    var parentFolderName: String?
    var folderDisplayName: String {
        return parentFolderName ?? "Mobile Uploads"
    }
    
    init(session: PermSession? = nil) {
        // Try to load session from keychain
        let sessionToUse: PermSession?
        if let providedSession = session {
            sessionToUse = providedSession
        } else {
            sessionToUse = try? SessionKeychainHandler().savedSession()
        }

        // If the session loaded but lacks a selectedArchive (fresh extension
        // install after host login, or stale session blob), pull from the
        // App Group snapshot the host mirrors on every selectedArchive write.
        if sessionToUse != nil, sessionToUse?.selectedArchive == nil,
           let mirrored = SharedSelectedArchiveStore.read() {
            sessionToUse?.selectedArchive = mirrored
        }

        PermSession.currentSession = sessionToUse
    }
    
    func archiveName() -> String {
        if let name = currentArchive?.fullName {
            return "<NAME> Archive".localized().replacingOccurrences(of: "<NAME>", with: "The \(name)")
        } else {
            return "Archive Name".localized()
        }
    }
    
    func archiveThumbnailUrl() -> String? {
        if let archiveThumnailUrl = currentArchive?.thumbURL1000 {
            return archiveThumnailUrl
        } else {
            return nil
        }
    }
    
    func hasUploadPermission() -> Bool {
        return currentArchive?.permissions().contains(.upload) ?? false
    }
    
    func hasActiveSession() -> Bool {
        guard let session = session else { 
            return false 
        }
        
        let expirationDate = session.expirationDate
        let currentTime = Date().timeIntervalSince1970
        let expirationTime = expirationDate.timeIntervalSince1970
        let isActive = expirationTime > currentTime
        
        return isActive
    }
    
    func processSelectedFiles(attachments: [NSItemProvider], then handler: @escaping (Bool) -> Void) {
        let dispatchGroup = DispatchGroup()
        let contentType = "public.item" // Updated from deprecated kUTTypeItem

        // loadItem completion handlers arrive on arbitrary queues — serialize the
        // appends so concurrent attachments can't race on the array.
        let appendQueue = DispatchQueue(label: "org.permanent.shareExtension.attachments")
        var filesURL: [URL] = []
        for provider in attachments {
            dispatchGroup.enter()
            provider.loadItem(forTypeIdentifier: contentType, options: nil) { (data, error) in
                defer { dispatchGroup.leave() }
                guard error == nil else { return }

                // Not every share hands us a file URL: screenshots arrive as UIImage
                // and some apps provide raw Data. Those used to be dropped SILENTLY
                // while the share completed as a success — persist them to a temp
                // file so they upload like any picked file.
                let url: URL?
                switch data {
                case let fileURL as URL:
                    url = fileURL
                case let raw as Data:
                    url = Self.persistToTempFile(raw, preferredExtension: Self.preferredExtension(for: provider) ?? "dat")
                case let image as UIImage:
                    // Preserve transparency: an image with an alpha channel (e.g. a PNG
                    // screenshot) would be flattened and re-typed by a forced JPEG, so encode
                    // it losslessly as PNG. Opaque images stay JPEG (far smaller for photos).
                    let alphaInfo = image.cgImage?.alphaInfo
                    let hasAlpha = alphaInfo != nil && alphaInfo != .none && alphaInfo != .noneSkipFirst && alphaInfo != .noneSkipLast
                    if hasAlpha, let png = image.pngData() {
                        url = Self.persistToTempFile(png, preferredExtension: "png")
                    } else {
                        url = image.jpegData(compressionQuality: 1.0).flatMap { Self.persistToTempFile($0, preferredExtension: "jpg") }
                    }
                default:
                    url = nil
                }
                if let url = url {
                    appendQueue.sync { filesURL.append(url) }
                }
            }
        }

        dispatchGroup.notify(queue: DispatchQueue.main) {
            self.selectedFiles = FileInfo.createFiles(from: filesURL, parentFolder: FolderInfo(folderId: -1, folderLinkId: -1))
            handler(!self.selectedFiles.isEmpty)
        }
    }

    /// Best-effort filename extension for a non-URL attachment, derived from the
    /// provider's registered type identifiers.
    private static func preferredExtension(for provider: NSItemProvider) -> String? {
        for identifier in provider.registeredTypeIdentifiers {
            if let ext = UTType(identifier)?.preferredFilenameExtension {
                return ext
            }
        }
        return nil
    }

    /// Writes an in-memory attachment to a unique temp file so the upload pipeline
    /// (which is URL-based) can carry it. Returns nil if the write fails.
    private static func persistToTempFile(_ data: Data, preferredExtension: String) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(preferredExtension)
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
    
    func cellConfigurationParameters(file: FileInfo) -> ShareExtensionCellConfiguration {
        var cellParameters: ShareExtensionCellConfiguration = (nil, nil, nil)
        
        cellParameters.fileSize = fileSize(file.url)
        cellParameters.fileImage = fileThumbnail(file.url)
        cellParameters.fileName = file.name
        
        return cellParameters
    }
    
    func fileSize(_ fileURL: URL) -> String? {
        var formatedFileSize: String?
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.countStyle = .file
        
        let fileSizeAny = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
        if let fileSizeInt = fileSizeAny?.fileSize {
            formatedFileSize = byteCountFormatter.string(for: fileSizeInt)
        }
        
        return formatedFileSize
    }
    
    func fileThumbnail(_ imageURL: URL) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        let maxDimensionInPixels: CGFloat = 300
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary

        guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions), let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }

        return UIImage(cgImage: downsampledImage)
    }
    
    func removeSelectedFile(_ file: FileInfo) {
        selectedFiles.removeAll(where: { $0 == file })
    }
    
    /// Result of the quota check: `nil` = enough space; `.insufficientSpace` = genuinely full;
    /// `.apiError` = the check itself couldn't complete (no session, network/decode failure).
    /// Distinguishing the last case stops a transient failure from being reported as "Storage
    /// Full" and cancelling the whole share.
    private func checkStorageQuota(completion: @escaping (StorageQuotaError?) -> Void) {
        // Calculate total size of selected files
        var totalFilesSize = 0
        selectedFiles.forEach { file in
            if let resources = try? file.url.resourceValues(forKeys: [.fileSizeKey]) {
                totalFilesSize += resources.fileSize ?? 0
            }
        }

        // Check if we have an active session and account ID
        guard let accountId = session?.account.accountID else {
            // Match the sibling branches: always deliver on main.
            DispatchQueue.main.async { completion(.apiError) }
            return
        }

        let getUserDataOperation = APIOperation(AccountEndpoint.getUserData(accountId: accountId))
        getUserDataOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<AccountVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    DispatchQueue.main.async {
                        completion(.apiError)
                    }
                    return
                }

                let spaceLeft = model.results[0].data?[0].accountVO?.spaceLeft ?? 0
                let hasEnoughSpace = spaceLeft > totalFilesSize

                DispatchQueue.main.async {
                    completion(hasEnoughSpace ? nil : .insufficientSpace)
                }

            case .error(_, _):
                DispatchQueue.main.async {
                    completion(.apiError)
                }
            default:
                DispatchQueue.main.async {
                    completion(.apiError)
                }
            }
        }
    }

    func uploadSelectedFiles(completion: @escaping ((Error?) -> Void)) {
        // First check if there's enough storage space
        checkStorageQuota { [self] quotaError in
            if let quotaError = quotaError {
                completion(quotaError)
                return
            }

            DispatchQueue.global().async { [self] in
                createDefaultFolderIfNeeded() { [self] error in
                    if let error = error {
                        DispatchQueue.main.async { completion(error) }
                        return
                    }
                    do {
                        // File copy is I/O — keep it off the main thread, collecting the
                        // destination URLs without touching shared state yet.
                        var copied: [(file: FileInfo, url: URL)] = []
                        for file in selectedFiles {
                            let tempLocation = try FileHelper().copyFile(withURL: URL(fileURLWithPath: file.url.path), name: file.id, usingAppSuiteGroup: ExtensionUploadManager.appSuiteGroup)
                            copied.append((file, tempLocation))
                        }
                        // Apply every `selectedFiles` (and FileInfo) mutation on main — the
                        // table view reads them there, so mutating off a background queue was a
                        // data race (torn reads / crash while scrolling during processing).
                        DispatchQueue.main.async {
                            for entry in copied {
                                entry.file.url = entry.url
                                entry.file.archiveId = self.currentArchive?.archiveID ?? -1
                            }
                            do {
                                // Atomic cross-process merge: `append` reads the queue and
                                // writes it back inside one file-coordination barrier, so the
                                // main app clearing completed uploads concurrently can't drop
                                // these files. (The old read-`savedFiles()`-then-`save()` had a
                                // lost-update gap between the two calls.)
                                try ExtensionUploadManager.shared.append(self.selectedFiles)
                                completion(nil)
                            } catch {
                                completion(error)
                            }
                        }
                    } catch {
                        DispatchQueue.main.async { completion(error) }
                    }
                }
            }
        }
    }
    
    func archiveUpdated() {
        parentFolder = nil
    }
    
    func updateSelectedFolder(withName name: String, folderInfo: FolderInfo) {
        parentFolder = folderInfo
        parentFolderName = name
        
        selectedFiles.forEach { fileInfo in
            fileInfo.folder = folderInfo
        }
    }
    
    func createDefaultFolderIfNeeded(completion: @escaping ((Error?) -> Void)) {
        guard parentFolder == nil else {
            completion(nil)
            return
        }
        
        getRoot { [self] status in
            switch status {
            case .success(let root):
                if let items = root.childItemVOS,
                   let uploadsFolder = items.filter({ $0.displayName == "Mobile Uploads" }).first,
                   let folderId = uploadsFolder.folderID,
                   let folderLinkId = uploadsFolder.folderLinkID {
                    // Mobile Uploads Folder Exists
                    selectedFiles.forEach({ $0.folder = FolderInfo(folderId: folderId, folderLinkId: folderLinkId) })
                    completion(nil)
                } else {
                    // Mobile Uploads Folder has to be created
                    let params: NewFolderParams = ("Mobile Uploads", root.folderLinkID ?? 0)
                    createNewFolder(params: params) { [self] folderVO in
                        guard let folderVO = folderVO,
                              let folderId = folderVO.folderID, let folderLinkId = folderVO.folderLinkID else {
                            completion(APIError.clientError)
                            return
                        }
                                            
                        selectedFiles.forEach({ $0.folder = FolderInfo(folderId: folderId, folderLinkId: folderLinkId) })
                        completion(nil)
                    }
                }
                
            case .error(_):
                completion(APIError.clientError)
                break
            }
        }
    }
}

extension ShareExtensionViewModel {
    typealias RootResponse = (RootStatus) -> Void
    
    enum RootStatus {
        case success(root: MinFolderVO)
        case error(message: String?)
    }
    
    func getRoot(then handler: @escaping RootResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getRoot)
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: GetRootResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                if model.isSuccessful == true {
                    self.onGetRootSuccess(model, handler)
                } else {
                    handler(.error(message: .errorMessage))
                }
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    private func onGetRootSuccess(_ model: GetRootResponse, _ handler: @escaping RootResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let myFilesFolder = folderVO.childItemVOS?.first(where: { $0.displayName == Constants.API.FileType.myFilesFolder }),
            let archiveNo = myFilesFolder.archiveNbr,
            let folderLinkId = myFilesFolder.folderLinkID
        else {
            handler(.error(message: .errorMessage))
            return
        }
        
        let params: NavigateMinParams = (archiveNo, folderLinkId, nil)
        navigateMin(params: params, backNavigation: false, then: handler)
    }
    
    func navigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping RootResponse) {
        let apiOperation = APIOperation(FilesEndpoint.navigateMin(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: NavigateMinResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                self.onNavigateMinSuccess(model, backNavigation, handler)
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    private func onNavigateMinSuccess(_ model: NavigateMinResponse, _ backNavigation: Bool, _ handler: @escaping RootResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO
        else {
            handler(.error(message: .errorMessage))
            return
        }
        
        handler(.success(root: folderVO))
    }
    
    func createNewFolder(params: NewFolderParams, then handler: @escaping ((MinFolderVO?) -> Void)) {
        let apiOperation = APIOperation(FilesEndpoint.newFolder(params: params))

        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: NavigateMinResponse = JSONHelper.convertToModel(from: response),
                    let folderVO = model.results?.first?.data?.first?.folderVO
                else {
                    handler(nil)
                    return
                }

                handler(folderVO)

            case .error(_, _):
                handler(nil)

            default:
                break
            }
        }
    }
}
