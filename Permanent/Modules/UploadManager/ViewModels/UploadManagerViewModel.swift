//
//  UploadManagerViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.10.2023.

import SwiftUI
import Foundation
import Photos

class UploadManagerViewModel: ObservableObject {
    var assets: [PHAsset] = []
    let currentArchive: ArchiveVOData?
    let folderNavigationStack: [FileModel]?
    @Published var assetURLs: [AssetDescriptor] = []
    @Published var isLoading: Bool = false
    
    init(assets: [PHAsset], currentArchive: ArchiveVOData?, folderNavigationStack: [FileModel]?) {
        self.assets = assets
        self.folderNavigationStack = folderNavigationStack
        self.currentArchive = currentArchive
    }
    
    @MainActor func getDescriptors() {
        let imageManager = PHCachingImageManager()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        
        Task {
            do {
                let descriptors = try await fetchAssetDescriptors(imageManager: imageManager, requestOptions: requestOptions)
                self.assetURLs = descriptors
            } catch {
                print("Failed to get URLs: \(error)")
            }
        }
    }
    
    private func fetchAssetDescriptors(imageManager: PHCachingImageManager, requestOptions: PHImageRequestOptions) async throws -> [AssetDescriptor] {
        return try await withThrowingTaskGroup(of: AssetDescriptor.self) { group in
            for asset in self.assets {
                group.addTask {
                    return try await withCheckedThrowingContinuation { continuation in
                        asset.getURL { descriptor in
                            if let descriptor = descriptor {
                                imageManager.requestImage(for: asset, targetSize: CGSize(width: 40, height: 40), contentMode: .aspectFill, options: requestOptions) { (image, _) in
                                    var descriptorWithImage = descriptor
                                    descriptorWithImage.image = image
                                    continuation.resume(returning: descriptorWithImage)
                                }
                            } else {
                                continuation.resume(throwing: URLError(.badURL))
                            }
                        }
                    }
                }
            }

            var descriptors: [AssetDescriptor] = []
            for try await descriptor in group {
                descriptors.append(descriptor)
            }

            return descriptors
        }
    }
    
    func getCurrentArchiveName() -> String {
        if let currentArchive = currentArchive {
            return currentArchive.fullName ?? ""
        }
        return ""
    }
    
    func getCurrentArchivePermission() -> String {
        if let currentArchive = currentArchive, let accessRole = currentArchive.accessRole {
            return AccessRole.roleForValue(accessRole).groupName
        }
        return ""
    }
    
    func getCurrentFolderPath() -> String {
        if let folderNavigationStack = folderNavigationStack {
            var fullPathComponents = folderNavigationStack.map { $0.name }
            _ = fullPathComponents.popLast()
            var fullPath = fullPathComponents.joined(separator: " \\ ")
            if folderNavigationStack.first?.type == FileType.privateRootFolder {
                if getCurrentFolder() == "Private Files" {
                    fullPath = "... \\ "
                } else {
                    fullPath = "... \\ \(fullPath) \\ "
                }
            }
            return fullPath
        }
        return ""
    }
    
    func getNumberOfAssets() -> String {
        var filesNumber = "\(assets.count)"
        if assets.count == 1 {
            filesNumber += " FILE"
        } else {
            filesNumber += " FILES"
        }
        return filesNumber
    }
    
    func getCurrentFolder() -> String {
        if let folderNavigationStack = folderNavigationStack {
            var fullPath = folderNavigationStack.last?.name ?? ""
            if folderNavigationStack.first?.type == FileType.privateRootFolder {
                fullPath = fullPath.replacingOccurrences(of: "My Files", with: "Private Files")
            }
            return fullPath
        }
        return ""
    }
    
//    To do - resolve upload mechanism
//    func didChooseFromPhotoLibrary(_ assets: [PHAsset], completion: @escaping ([URL]) -> Void) {
//        let dispatchGroup = DispatchGroup()
//        var urls: [URL] = []
//        
//        assets.forEach { photo in
//            dispatchGroup.enter()
//      
//            photo.getURL { descriptor in
//                guard let fileDescriptor = descriptor else {
//                    dispatchGroup.leave()
//                    return
//                }
//      
//                do {
//                    let localURL = try FileHelper().copyFile(withURL: fileDescriptor.url, name: fileDescriptor.name)
//                    urls.append(localURL)
//                } catch {
//                    print(error)
//                }
//      
//                dispatchGroup.leave()
//            }
//        }
//        
//        dispatchGroup.notify(queue: .main, execute: {
//            completion(urls)
//        })
//    }
    
    func deleteAsset(at descriptor: AssetDescriptor) {
        if let index = assetURLs.firstIndex(where: { $0 == descriptor }) {
            assetURLs.remove(at: index)
        }
    }
}
