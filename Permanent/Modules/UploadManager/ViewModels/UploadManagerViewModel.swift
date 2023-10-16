//
//  UploadManagerViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 03.10.2023.

import SwiftUI
import Foundation
import Photos

class UploadManagerViewModel: ObservableObject {
    @Published var assets: [PHAsset] = []
    let currentArchive: ArchiveVOData?
    let folderNavigationStack: [FileModel]?
    @Published var assetURLs: [AssetDescriptor] = []
    @Published var isLoading: Bool = false
    @Published var numberOfFiles: String = ""
    var numberOfAssets: String {
        var filesNumber = "\(assets.count)"
        if assets.count == 1 {
            filesNumber += " FILE"
        } else {
            filesNumber += " FILES"
        }
        return filesNumber
    }
    
    var completionHandler: (([PHAsset]) -> Void)?
    
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
        guard let folderNavigationStack = folderNavigationStack else { return "" }
        
        var fullPathComponents = folderNavigationStack.map { $0.name }
        _ = fullPathComponents.popLast()
        var fullPath = fullPathComponents.joined(separator: " \\ ")
        
        switch folderNavigationStack.first?.type {
        case .privateRootFolder:
            fullPath = adjustPathForPrivateRootFolder(fullPath)
        case .privateFolder:
            fullPath = adjustPathForPrivateFolder(fullPath)
        case .publicRootFolder:
            fullPath = adjustPathForPublicRootFolder(fullPath)
        default:
            break
        }
        
        return fullPath
    }
    
    private func adjustPathForPrivateRootFolder(_ path: String) -> String {
        var newPath = path
        if getCurrentFolder() == "Private Files" {
            newPath = "... \\ "
        } else {
            newPath = "... \\ \(path) \\ "
        }
        return newPath.replacingOccurrences(of: "My Files", with: "Private Files")
    }
    
    private func adjustPathForPrivateFolder(_ path: String) -> String {
        var newPath = path
        if !path.isEmpty {
            newPath = "\(path) \\ "
        }
        return "... \\ Shared Files \\ \(newPath)"
    }
    
    private func adjustPathForPublicRootFolder(_ path: String) -> String {
        var newPath = path
        if getCurrentFolder() == "Public" {
            newPath = "... \\ "
        } else {
            newPath = "... \\ \(path) \\ "
        }
        return newPath.replacingOccurrences(of: "Public", with: "Public Files")
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
    
    func deleteAsset(at descriptor: AssetDescriptor) {
        if let index = assetURLs.firstIndex(where: { $0 == descriptor }) {
            assetURLs.remove(at: index)
            assets.remove(at: index)
        }
    }
}
