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
    var currentArchive: ArchiveVOData?
    var selectedFiles: [FileInfo] = []
    
    init() {
//        currentArchive = try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.archive)
    }
    
    func archiveName() -> String {
        if let name = currentArchive?.fullName {
            return "<NAME> Archive".localized().replacingOccurrences(of: "<NAME>", with: "The \(name)")
        } else {
            return "Archive name was not found".localized()
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
    
    func uploadSelectedFiles(completion: @escaping ((Error?) -> Void)) {
        DispatchQueue.global().async { [self] in
            do {
                try selectedFiles.forEach { file in
                    let tempLocation = try FileHelper().copyFile(withURL: URL(fileURLWithPath: file.url.path), usingAppSuiteGroup: ExtensionUploadManager.appSuiteGroup)
                    file.url = tempLocation
                }
                
                try ExtensionUploadManager.shared.save(files: selectedFiles)
                
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}
