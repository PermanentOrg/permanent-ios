//
//  ShareExtensionViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.07.2022.
//

import Foundation
import UIKit
import MobileCoreServices

typealias ShareExtensionCellConfiguration = (fileImage: UIImage?, fileName: String?, fileSize: String?)

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
    
    init(session: PermSession? = try? SessionKeychainHandler().savedSession()) {
        PermSession.currentSession = session
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
        guard let expirationDate = session?.authState.lastTokenResponse?.accessTokenExpirationDate else { return false }
        return expirationDate.timeIntervalSince1970 > Date().timeIntervalSince1970
    }
    
    func processSelectedFiles(attachments: [NSItemProvider], then handler: @escaping (Bool) -> Void) {
        let dispatchGroup = DispatchGroup()
        let contentType = kUTTypeItem as String
        
        var filesURL: [URL] = []
        for provider in attachments {
            dispatchGroup.enter()
            provider.loadItem(forTypeIdentifier: contentType, options: nil) { (data, error) in
                guard error == nil else {
                    return
                }
                
                if let url = data as? URL {
                    filesURL.append(url)
                }
                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            self.selectedFiles = FileInfo.createFiles(from: filesURL, parentFolder: FolderInfo(folderId: -1, folderLinkId: -1))
            handler(!self.selectedFiles.isEmpty)
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
    
    func uploadSelectedFiles(completion: @escaping ((Error?) -> Void)) {
        DispatchQueue.global().async { [self] in
            createDefaultFolderIfNeeded() { [self] error in
                if error != nil {
                    completion(error)
                } else {
                    do {
                        try selectedFiles.forEach { file in
                            let tempLocation = try FileHelper().copyFile(withURL: URL(fileURLWithPath: file.url.path), name: file.id, usingAppSuiteGroup: ExtensionUploadManager.appSuiteGroup)
                            file.url = tempLocation
                            file.archiveId = currentArchive?.archiveID ?? -1
                        }
                        
                        let savedFiles = try ExtensionUploadManager.shared.savedFiles()
                        selectedFiles.append(contentsOf: savedFiles)
                        try ExtensionUploadManager.shared.save(files: selectedFiles)
                        
                        completion(nil)
                    } catch {
                        completion(error)
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
                
            case .error(let message):
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
