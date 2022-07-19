//
//  ShareExtensionViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.07.2022.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

typealias ConfigurationForShareExtensionCell = (fileImage: UIImage?, fileName: String?, fileSize: String?)

class ShareExtensionViewModel: ViewModelInterface {
    var currentArchive: ArchiveVOData?
    var selectedFiles: [FileInfo] = []
    var filesURL: [URL] = []
    
    static let cancelButtonPressed = NSNotification.Name("ShareExtensionViewModel.cancelButtonPressed")
    
    init() {
        currentArchive = try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.archive)
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
    
    func noUploadPermission() -> Bool {
        return !(currentArchive?.permissions().contains(.upload) ?? false)
    }
    
    func processSelectedFiles(attachments: [NSItemProvider], then handler: @escaping (Bool) -> Void) {
        let dispatchGroup = DispatchGroup()
        let contentType = UTType.item.identifier
        
        for provider in attachments {
            dispatchGroup.enter()
            provider.loadItem(forTypeIdentifier: contentType, options: nil) { [unowned self] (data, error) in
                guard error == nil else {
                    NotificationCenter.default.post(name: Self.cancelButtonPressed, object: self)
                    return
                }
                
                if let nsUrl = data as? NSURL, let path = nsUrl.path {
                    do {
                        let tempLocation = try FileHelper().copyFile(withURL: URL(fileURLWithPath: path), usingAppSuiteGroup: ExtensionUploadManager.appSuiteGroup)
                        filesURL.append(tempLocation)
                    } catch {
                        print(error)
                    }
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: DispatchQueue.main) {
            self.selectedFiles = FileInfo.createFiles(from: self.filesURL, parentFolder: FolderInfo(folderId: -1, folderLinkId: -1))
            handler(!self.selectedFiles.isEmpty)
        }
    }
    
    func getCellConfigurationParameters(file: FileInfo) -> ConfigurationForShareExtensionCell {
        var cellParameters: ConfigurationForShareExtensionCell = (nil, nil, nil)
        
        cellParameters.fileSize = getFileSize(file.url)
        cellParameters.fileImage = resizeImageForUpload(file.url)
        cellParameters.fileName = file.name
        
        return cellParameters
    }
    
    func getFileSize(_ fileURL: URL) -> String? {
        var formatedFileSize: String?
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.countStyle = .file
        
        let fileSizeAny = try! fileURL.resourceValues(forKeys: [.fileSizeKey])
        if let fileSizeInt = fileSizeAny.fileSize {
            formatedFileSize = byteCountFormatter.string(for: fileSizeInt)
        }
        
        return formatedFileSize
    }
    
    func resizeImageForUpload(_ imageURL: URL) -> UIImage? {
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
}
