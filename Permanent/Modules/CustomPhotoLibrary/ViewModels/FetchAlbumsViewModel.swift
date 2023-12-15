//
//  FetchAlbumsViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.12.2023.

import Foundation
import Photos
import UIKit
import SwiftUI

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

class FetchAlbumsViewModel: ObservableObject {
    
    @Published var assets: [PHAsset] = []
    @Published var isLoadingPhotos: Bool = false
    
    var imageCachingManager = PHCachingImageManager()
    
    init() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) {[weak self] status in
            switch status {
            case .authorized:
                self?.loadImagesForSegment(segment: 0)
            default:
                break
            }
        }
    }
    
    func loadImagesForSegment(segment: Int) {
        isLoadingPhotos = true
        if segment == 0 {
            imageCachingManager.allowsCachingHighQualityImages = true
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.includeHiddenAssets = false
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d || mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
            fetchOptions.sortDescriptors = [
                NSSortDescriptor(key: "creationDate", ascending: false)
            ]
            
            DispatchQueue.main.async {
                let result = PHAsset.fetchAssets(with: fetchOptions)
                var assets: [PHAsset] = []
                result.enumerateObjects { object, index, stop in
                    assets.append(object)
                }
                self.assets = assets
            }
        } else {
            var assets: [PHAsset] = []
            self.assets = assets
        }
        isLoadingPhotos = false
    }
    
    func fetchImage(
            byLocalIdentifier localId: String,
            targetSize: CGSize = CGSize(width: 150, height: 150),
            contentMode: PHImageContentMode = .aspectFill
        ) async throws -> Image? {
            guard let asset = assets.first(where: { $0.localIdentifier == localId }) else {
                throw QueryError.NotFound
            }
            
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = false
            options.isSynchronous = false
            
            return try await withCheckedThrowingContinuation { [weak self] continuation in
                self?.imageCachingManager.requestImage(
                    for: asset,
                    targetSize: targetSize,
                    contentMode: contentMode,
                    options: options,
                    resultHandler: { image, info in
                        if let error = info?[PHImageErrorKey] as? Error {
                            continuation.resume(throwing: error)
                            return
                        }
                        if let image = image {
                            continuation.resume(returning: Image(uiImage: (image)))
                        }
                    }
                )
            }
        }
}
