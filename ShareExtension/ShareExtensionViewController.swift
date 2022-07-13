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
        
        initUI()
        setupTableView()
        handleSharedFile()
    }
    
    fileprivate func initUI() {
        styleNavBar()
        
        title = "Permanent"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Upload".localized(), style: .plain, target: self, action: #selector(didTapUpload))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(didTapCancel))
        
        saveFolderLabel.text = "Root folder"
        userNameImageView.image = UIImage(named: "placeholder")
        saveFolderImageView.image = UIImage(named: "shareFolder")
        
        userNameLabel.font = Text.style4.font
        saveFolderLabel.font = Text.style4.font

        userNameLabel.textColor = .black
        saveFolderLabel.textColor = .black
        separatorOneView.backgroundColor = .lightGray
    }
    
    func styleNavBar() {
        navigationController?.navigationBar.tintColor = .white
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .darkBlue
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont(name: "OpenSans-Bold", size: 20)!
            ]
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
        } else {
            navigationController?.navigationBar.barTintColor = .darkBlue
            navigationController?.navigationBar.isTranslucent = false
            navigationController?.navigationBar.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: UIFont(name: "OpenSans-Bold", size: 20)!
            ]
        }
        tableView.backgroundColor = .white
    }
    
    fileprivate func setupTableView() {
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: String(describing: FileDetailsTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: FileDetailsTableViewCell.self))
    }
    
    private func handleSharedFile() {
        guard let archive: ArchiveVOData = try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.archive) else { return }
        
        let dispatchGroup = DispatchGroup()
        
        if let name = archive.fullName, let archiveThumnailUrl = archive.thumbURL1000 {
            userNameLabel.text = "<NAME> Archive".localized().replacingOccurrences(of: "<NAME>", with: "\(name)")
            userNameImageView.load(urlString: archiveThumnailUrl)
        }

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
            if let folderId: Int? = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.archiveFolderId),
                let folderLinkId: Int? = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.archiveFolderLinkId),
            let rootFolderId = folderId, let rootFolderLinkId = folderLinkId {
                self.selectedFiles = FileInfo.createFiles(from: self.filesURL, parentFolder: FolderInfo(folderId: rootFolderId, folderLinkId: rootFolderLinkId))
            }
            
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
            if let fileData = NSData(contentsOf: selectedFiles[indexPath.row].url) {
                let byteCountFormatter = ByteCountFormatter()
                byteCountFormatter.countStyle = .file
                
                cell.configure(fileImage: UIImage(data: fileData as Data), fileName: selectedFiles[indexPath.row].name, fileSize: byteCountFormatter.string(for: Int64(fileData.count)))
            }
            tableViewCell = cell
        }
        return tableViewCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(60)
    }
}
