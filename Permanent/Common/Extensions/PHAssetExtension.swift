//
//  PHAssetExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 26/10/2020.
//

import Photos
import UIKit

struct AssetDescriptor: Hashable {
    let url: URL
    let name: String
    var image: UIImage?
}

extension PHAsset {
    func getURL(completionHandler: @escaping ((_ descriptor: AssetDescriptor?) -> Void)) {
        if self.mediaType == .image {
            let options = PHContentEditingInputRequestOptions()
            options.isNetworkAccessAllowed = true
            options.canHandleAdjustmentData = { (_: PHAdjustmentData) -> Bool in
                false
            }
            self.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput: PHContentEditingInput?, _: [AnyHashable: Any]) -> Void in
                guard let url = contentEditingInput?.fullSizeImageURL as URL? else {
                    completionHandler(nil)
                    return
                }
                
                var fileName = url.lastPathComponent
                if url.lastPathComponent.contains("FullSizeRender") {
                    let fileExtention = url.lastPathComponent.components(separatedBy: ".").last ?? ""
                    fileName = url.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
                    if fileExtention.isNotEmpty { fileName.append(".\(fileExtention)") }
                }
                
                let descriptor = AssetDescriptor(url: url, name: fileName)
                completionHandler(descriptor)
            })
        } else if self.mediaType == .video {
            let options = PHVideoRequestOptions()
            options.version = .original
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(forVideo: self, options: options, resultHandler: { (asset: AVAsset?, _: AVAudioMix?, _: [AnyHashable: Any]?) -> Void in
                if let urlAsset = asset as? AVURLAsset {
                    let url: URL = urlAsset.url as URL
                    let fileName = url.lastPathComponent
                    
                    let descriptor = AssetDescriptor(url: url, name: fileName)
                    completionHandler(descriptor)
                } else {
                    completionHandler(nil)
                }
            })
        }
    }
}
