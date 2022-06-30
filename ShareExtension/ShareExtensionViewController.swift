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
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    
    var selectedFiles: [FileInfo] = []
    var filesURL: [URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        setupTableView()
        handleSharedFile()
    }
    
    fileprivate func initUI() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Upload".localized(), style: .plain, target: self, action: #selector(didTapUpload))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(didTapCancel))
        navigationController?.navigationBar.standardAppearance.configureWithOpaqueBackground()
        navigationController?.navigationBar.standardAppearance.backgroundColor = .white
        navigationController?.navigationBar.standardAppearance.shadowColor = .clear
        navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
    }
    
    fileprivate func setupTableView() {
        tableView.separatorStyle = .none
    }
    
    private func handleSharedFile() {
        let dispatchGroup = DispatchGroup()
        
        let attachments = (self.extensionContext?.inputItems.first as? NSExtensionItem)?.attachments ?? []
        let contentType = UTType.jpeg.identifier as String
        for provider in attachments {
            dispatchGroup.enter()
            provider.loadItem(forTypeIdentifier: contentType, options: nil) { [unowned self] (data, error) in
                guard error == nil else { return }
                
                if let nsUrl = data as? NSURL, let path = nsUrl.path {
                    do {
                        let tempLocation = try FileHelper().copyFile(withURL: URL(fileURLWithPath: path))
                        filesURL.append(tempLocation)
                    } catch {
                        print(error)
                    }
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.notify(queue: DispatchQueue.main) {
            self.selectedFiles = FileInfo.createFiles(from: self.filesURL, parentFolder: FolderInfo(folderId: 44677, folderLinkId: 114553))
            
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
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: "fileDetailsCell", for: indexPath)
        if let fileData = NSData(contentsOf: selectedFiles[indexPath.row].url) {
            let byteCountFormatter = ByteCountFormatter()
            byteCountFormatter.countStyle = .file
            
            tableViewCell.textLabel?.text = selectedFiles[indexPath.row].name
            tableViewCell.detailTextLabel?.text = byteCountFormatter.string(for: Int64(fileData.count))
            tableViewCell.imageView?.image = UIImage(data: fileData as Data)
        }
        return tableViewCell
    }
}
