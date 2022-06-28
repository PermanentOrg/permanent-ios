//
//  ShareExtensionViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.08.2020.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

@objc(ShareExtensionViewController)
class ShareExtensionViewController: UIViewController {
    @IBOutlet weak var shareFileName: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        handleSharedFile()
    }
    
    private func handleSharedFile() {
        // extracting the path to the URL that is being shared
        let attachments = (self.extensionContext?.inputItems.first as? NSExtensionItem)?.attachments ?? []
        let contentType = UTType.jpeg.identifier as String
        for provider in attachments {
            provider.loadItem(forTypeIdentifier: contentType, options: nil) { [unowned self] (data, error) in
                guard error == nil else { return }
                
                if let nsUrl = data as? NSURL,
                   let stringUrl = nsUrl.absoluteURL,
                   let imageData = try? Data(contentsOf: stringUrl) {
                    self.save(imageData, key: "imageData", value: imageData, fileName: stringUrl.lastPathComponent)
                }
            }
        }
    }
    
    private func save(_ data: Data, key: String, value: Any, fileName: String) {
        if let image = UIImage(data: data) {
            shareFileName.text = fileName
        }
    }
}
