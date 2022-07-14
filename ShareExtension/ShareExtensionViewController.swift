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
class ShareExtensionViewController: BaseViewController<ShareExtensionViewModel> {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var saveFolderLabel: UILabel!
    @IBOutlet weak var separatorOneView: UIView!
    @IBOutlet weak var userNameImageView: UIImageView!
    @IBOutlet weak var saveFolderImageView: UIImageView!
    
    var selectedFiles: [FileInfo] = []
    var filesURL: [URL] = []
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return [.portrait]
        } else {
            return [.all]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = ShareExtensionViewModel()
        initUI()
        setupTableView()
        handleSharedFile()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    fileprivate func initUI() {
        styleNavBar()
        
        title = "Permanent"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Upload".localized(), style: .plain, target: self, action: #selector(didTapUpload))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(didTapCancel))
        
        saveFolderLabel.text = "Mobile Uploads"
        userNameImageView.image = UIImage(named: "placeholder")
        saveFolderImageView.image = UIImage(named: "shareFolder")
        
        userNameLabel.font = Text.style4.font
        saveFolderLabel.font = Text.style4.font
        
        userNameLabel.textColor = .black
        saveFolderLabel.textColor = .black
        separatorOneView.backgroundColor = .lightGray
    }
    
    fileprivate func setupTableView() {
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: String(describing: FileDetailsTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: FileDetailsTableViewCell.self))
        
        tableView.backgroundColor = .white
    }
    
    private func handleSharedFile() {
        guard let archive: ArchiveVOData = try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.archive) else { return }
        
        if let name = archive.fullName, let archiveThumnailUrl = archive.thumbURL1000 {
            userNameLabel.text = "<NAME> Archive".localized().replacingOccurrences(of: "<NAME>", with: "The \(name)")
            userNameImageView.load(urlString: archiveThumnailUrl)
        }
        
        if !archive.permissions().contains(.upload) {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Uh oh", message: "You are a viewer of the selected archive and do not have permission to upload files.".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: .ok, style: .default, handler: {_ in
                    self.didTapCancel()
                }))
                
                self.present(alert, animated: true)
            }
        }
        
        let dispatchGroup = DispatchGroup()
        
        let attachments = (self.extensionContext?.inputItems.first as? NSExtensionItem)?.attachments ?? []
        let contentType = UTType.item.identifier
        for provider in attachments {
            dispatchGroup.enter()
            provider.loadItem(forTypeIdentifier: contentType, options: nil) { [unowned self] (data, error) in
                guard error == nil else {
                    didTapCancel()
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
            
            self.activityIndicator.stopAnimating()
            self.statusLabel.isHidden = true
            self.tableView.reloadData()
        }
    }
    
    @objc func didTapUpload() {
        do {
            try ExtensionUploadManager.shared.save(files: selectedFiles)
        } catch {
            let alert = UIAlertController(title: "Error".localized(), message: "ErrorMessage".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok".localized(), style: .default, handler: nil))
            
            self.present(alert, animated: true)
        }
        
        extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    @objc func didTapCancel() {
        extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
    }
}

extension ShareExtensionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var tableViewCell = UITableViewCell()
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: FileDetailsTableViewCell.self)) as? FileDetailsTableViewCell {
            var formatedFileSize: String?
            let byteCountFormatter = ByteCountFormatter()
            byteCountFormatter.countStyle = .file
            
            let fileSizeAny = try! selectedFiles[indexPath.row].url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSizeInt = fileSizeAny.fileSize {
                formatedFileSize = byteCountFormatter.string(for: fileSizeInt)
            }
            
            let fileThumbnail = resizeForUpload(selectedFiles[indexPath.row].url)
            
            cell.configure(fileImage: fileThumbnail, fileName: selectedFiles[indexPath.row].name, fileSize: formatedFileSize)
            tableViewCell = cell
        }
        return tableViewCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(60)
    }
    
    private func resizeForUpload(_ imageURL: URL) -> UIImage? {
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
