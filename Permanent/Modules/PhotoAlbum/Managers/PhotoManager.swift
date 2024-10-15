//
//  PhotoManager.swift
//  VSPFetchAssets
//
//  Created by Flaviu Silaghi on 30.09.2024.

import Foundation
import Photos
import UIKit

class PhotoManager {
    var folderInfo: FolderInfo?
    
    private var isLoading = false
    
    static let shared = PhotoManager()
    
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    init() {
        getRoot(then: { status in
            self.start()
        })
    }
    
    func getRoot(then handler: @escaping ServerResponse) {
        let currentArchive = AuthenticationManager.shared.session?.selectedArchive
        let apiOperation = APIOperation(FilesEndpoint.getPublicRoot(archiveNbr: currentArchive!.archiveNbr!))
        
        apiOperation.execute(in: APIRequestDispatcher()) {[weak self] result in
            switch result {
            case .json(let response, _):
                guard let model: GetRootResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                if model.isSuccessful == true {
                    let folderVO = model.results?.first?.data?.first?.folderVO
                    if let folderID = folderVO?.folderID, let folderLinkId = folderVO?.folderLinkID {
                        self?.folderInfo = FolderInfo(folderId: folderID, folderLinkId: folderLinkId)
                    }
                    handler(.success)
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
    
    func start() {
        self.checkForNewPhotos { assets in
            self.startUpload(assets: assets)
        }
    }
    
    func checkForNewPhotos(completion: @escaping ([PHAsset]) -> Void) {
        guard !isLoading else { return }
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let lastCheckedDate = UserDefaults.standard.object(forKey: "lastCheckedPhotoDate") as? Date

        if let lastCheckedDate = lastCheckedDate {
            let predicate = NSPredicate(format: "creationDate > %@", lastCheckedDate as CVarArg)
            fetchOptions.predicate = predicate
        }

        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var assets: [PHAsset] = []
        result.enumerateObjects { object, index, stop in
            assets.append(object)
        }
        
        print("assets fetched:\(assets.count)")

        completion(assets)
    }
    
    func startUpload(assets: [PHAsset]) {
        Task {
            let chunkedAssets = assets.chunked(into: 10)
            for chunk in chunkedAssets {
                isLoading = true
                do {
                    backgroundTask = await UIApplication.shared.beginBackgroundTask(withName: "com.permanent.backgroundTask") {
                        OtherUploadManager.shared.uploadQueue.cancelAllOperations()
                        UIApplication.shared.endBackgroundTask(self.backgroundTask)
                        self.backgroundTask = .invalid
                        self.isLoading = false
                        print("canceling background task")
                    }

                    let fileInfos = try await getURLS(assets: chunk)
                    await OtherUploadManager.shared.upload(files: fileInfos) // Wait for upload to complete
                    
                    await UIApplication.shared.endBackgroundTask(backgroundTask)
                    isLoading = false
                    backgroundTask = .invalid
                } catch {
                    print("Error processing chunk: \(error)")
                }
            }
        }
    }

    func getURLS(assets: [PHAsset]) async throws -> [FileInfo] {
        try await withThrowingTaskGroup(of: FileInfo.self) { group in
            var fileInfos: [FileInfo] = []

            for photo in assets {
                group.addTask {
                    guard let descriptor = await photo.getURL() else {
                        throw NSError(domain: "PhotoError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get URL for photo"])
                    }

                    do {
                        let localURL = try FileHelper().copyFile(withURL: descriptor.url, name: descriptor.name)
                        let fileInfo = FileInfo(withURL: localURL, named: descriptor.name, assetId: photo.localIdentifier, folder: self.folderInfo!, creationDate: photo.creationDate)
                        return fileInfo
                    } catch {
                        print(error)
                        throw error
                    }
                }
            }

            for try await fileInfo in group {
                fileInfos.append(fileInfo)
            }

            return fileInfos
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
