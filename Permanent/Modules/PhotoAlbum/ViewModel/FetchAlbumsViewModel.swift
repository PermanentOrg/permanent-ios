//
//  FetchAlbumsViewModel.swift
//  VSPFetchAssets
//
//  Created by Flaviu Silaghi on 18.10.2023.

import Foundation
import Photos
import UIKit

struct PHFetchResultCollection: RandomAccessCollection, Equatable {

    typealias Element = PHAsset
    typealias Index = Int

    let fetchResult: PHFetchResult<PHAsset>

    var endIndex: Int { fetchResult.count }
    var startIndex: Int { 0 }

    subscript(position: Int) -> PHAsset {
        fetchResult.object(at: fetchResult.count - position - 1)
    }
}

enum QueryError: Error {
    case NotFound
}

class FetchedAssets: Identifiable, ObservableObject {
    let id = UUID()
    var asset: PHAsset
    @Published var isUploaded: Bool
    
    init(asset: PHAsset, isUploaded: Bool) {
        self.asset = asset
        self.isUploaded = isUploaded
    }
}

class FetchAlbumsViewModel: ObservableObject {
    
    @Published var assets: [FetchedAssets] = []
    
    @Published var id = UUID().uuidString
    
    var imageCachingManager = PHCachingImageManager()
    
    init() {
        NotificationCenter.default.addObserver(forName: OtherUploadOperation.uploadFinishedNotification, object: nil, queue: nil) {[weak self] notif in
            print("update photo")
            guard let operation = notif.object as? OtherUploadOperation else { return }
            self?.update(fileInfo: operation.file)
        }
        
        PHPhotoLibrary.requestAuthorization(for: .readWrite) {[weak self] status in
            switch status {
            case .authorized:
                self?.fetchAssets()
                PhotoManager.shared
            default:
                break
            }
        }
    }
    
    func update(fileInfo: FileInfo) {
        assets.first(where: {$0.asset.localIdentifier == fileInfo.assetID })?.isUploaded = true
    }
    
    func fetchAssets() {
        imageCachingManager.allowsCachingHighQualityImages = false
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeHiddenAssets = false
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true)
        ]
        
        DispatchQueue.main.async {
            let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var assets: [FetchedAssets] = []
            result.enumerateObjects { object, index, stop in
                assets.append(FetchedAssets(asset: object, isUploaded: self.isUploaded(asset: object)))
            }
            self.assets = assets
        }
    }
    
    func fetchImage(
        byLocalIdentifier localId: String,
        targetSize: CGSize = PHImageManagerMaximumSize,
        contentMode: PHImageContentMode = .default
    ) async throws -> UIImage? {
        guard let fetchedAsset = assets.first(where: { $0.asset.localIdentifier == localId }) else {
            throw QueryError.NotFound
        }
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.imageCachingManager.requestImage(
                for: fetchedAsset.asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options,
                resultHandler: { image, info in
                    if let error = info?[PHImageErrorKey] as? Error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: image)
                }
            )
        }
    }
    
    func isUploaded(asset: PHAsset) -> Bool {
        return UserDefaultManager().getFiles().contains(asset.localIdentifier)
    }
    
}
