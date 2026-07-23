//
//  FileDetailsViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 01.03.2021.
//

import UIKit
import SwiftUI

class FileDetailsViewController: BaseViewController<FilePreviewViewModel> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .phone ? [.portrait] : [.all]
    }
    
    enum CellType {
        case thumbnail
        case segmentedControl
        case name
        case description
        case date
        case location
        case tags
        case uploaded
        case lastModified
        case created
        case fileCreated
        case size
        case fileType
        case originalFileName
        case originalFileType
    }
    
    weak var delegate: FilePreviewNavigationControllerDelegate?
    
    var file: FileModel!
    let fileHelper = FileHelper()
    var recordVO: RecordVOData? {
        return viewModel?.recordVO?.recordVO
    }
    
    let topSectionCells: [CellType] = [.thumbnail, .segmentedControl]
    var bottomSectionCells: [CellType] = [.name, .description, .date, .location, .tags]
    
    let documentInteractionController = UIDocumentInteractionController()
    
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.45)

        collectionView.collectionViewLayout = layout
        collectionView.backgroundColor = .black

        collectionView.register(FileDetailsTopCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsTopCollectionViewCell.identifier)
        collectionView.register(FileDetailsMenuCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsMenuCollectionViewCell.identifier)
        collectionView.register(FileDetailsBottomCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsBottomCollectionViewCell.identifier)
        collectionView.register(FileDetailsDateCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsDateCollectionViewCell.identifier)
        collectionView.register(FileDetailsMapViewCellCollectionViewCell.nib(), forCellWithReuseIdentifier: FileDetailsMapViewCellCollectionViewCell.identifier)
        collectionView.register(TagsNamesCollectionViewCell.nib(), forCellWithReuseIdentifier: TagsNamesCollectionViewCell.identifier)
        
        if viewModel == nil {
            viewModel = FilePreviewViewModel(file: file)
            viewModel?.getRecord(file: file, then: { record in
                self.title = record?.recordVO?.displayName
                self.collectionView.reloadData()
            })
            
            title = file.name
        } else {
            title = viewModel!.recordVO?.recordVO?.displayName
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidUpdateData(_:)), name: .filePreviewVMDidSaveData, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onFailedUpdateData(_:)), name: .filePreviewVMSaveDataFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidUpdateShares(_:)), name: ShareLinkViewModel.didUpdateSharesNotifName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidUpdateShares(_:)), name: ShareItemViewModel.didUpdateSharesNotifName, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.endEditing(true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func initUI() {
        view.backgroundColor = .black
        styleNavBar()
        
        let leftButtonImage: UIImage!
        leftButtonImage = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))

        let closeButton = UIBarButtonItem(image: leftButtonImage, style: .plain, target: self, action: #selector(closeButtonAction(_:)))
        closeButton.accessibilityIdentifier = "fileDetailsCloseButton"
        navigationItem.leftBarButtonItem = closeButton

        let shareButton = UIBarButtonItem(image: UIImage(named: "more")!, style: .plain, target: self, action: #selector(showShareMenu(_:)))
        shareButton.accessibilityIdentifier = "fileDetailsShareButton"
        navigationItem.rightBarButtonItem = shareButton
    }
    
    override func styleNavBar() {
        super.styleNavBar()
        
        navigationController?.navigationBar.standardAppearance.backgroundColor = .black
        navigationController?.navigationBar.scrollEdgeAppearance?.backgroundColor = .black
    }
    
    @objc func showShareMenu(_ sender: Any) {
        var menuItems: [FileMenuViewModel.MenuItem] = []
        
        // Share to Permanent - only for files with ownership
        if file.permissions.contains(.ownership) {
            menuItems.append(FileMenuViewModel.MenuItem(type: .shareToPermanent, action: nil))
        }
        
        // Share to another app - for files with share permission (not folders)
        if file.permissions.contains(.share) && file.type.isFolder == false {
            menuItems.append(FileMenuViewModel.MenuItem(type: .shareToAnotherApp, action: { [self] in
                shareWithOtherApps()
            }))
        }
        
        // Publish on the web - for files with delete permission
        if file.permissions.contains(.delete) {
            menuItems.append(FileMenuViewModel.MenuItem(type: .publish, action: { [self] in
                publishAction()
            }))
        }
        
        // Download - for files with read permission (not folders)
        if file.permissions.contains(.read) && file.type.isFolder == false {
            menuItems.append(FileMenuViewModel.MenuItem(type: .download, action: { [weak self] in
                guard let self = self else { return }
                // Store the file reference before dismissing
                let fileToDownload = self.file!
                
                // First dismiss the menu
                if let menuHostingController = self.presentedViewController {
                    menuHostingController.dismiss(animated: true) {
                        // Then dismiss the preview and notify delegate
                        self.navigationController?.dismiss(animated: true) {
                            // Use delegate to request download from MainViewController
                            self.delegate?.filePreviewNavigationControllerRequestsDownload(self, file: fileToDownload)
                        }
                    }
                }
            }))
        }
        
        let swiftUIView = FileMoreMenuView(
            fileViewModel: file,
            menuItems: menuItems,
            onDismiss: { [weak self] in
                // Only dismiss the menu overlay, not the details view
                self?.presentedViewController?.dismiss(animated: true)
            },
            onShareManagementRequested: { [weak self] file in
                // Don't dismiss the details view - just dismiss the menu and present share management on top
                if let hostingController = self?.presentedViewController {
                    hostingController.dismiss(animated: true) {
                        self?.presentShareManagement(for: file)
                    }
                }
            },
            downloadHandler: nil
        )
        
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        hostingController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        hostingController.view.backgroundColor = UIColor.clear
        
        present(hostingController, animated: true)
    }
    
    private func presentShareManagement(for file: FileModel) {
        let shareContainerView = ShareContainerView(fileModel: file)
        let hostingController = UIHostingController(rootView: shareContainerView)
        hostingController.modalPresentationStyle = UIModalPresentationStyle.pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = hostingController.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
        }
        present(hostingController, animated: true)
    }
    
    @objc func closeButtonAction(_ sender: Any) {
        // Hand off to the delegate (the preview pager), which dismisses the whole
        // presentation chain in one animated transition. Dismissing this details modal
        // here first (animated: false) would briefly reveal the fullscreen preview
        // underneath before it too gets dismissed — a visible flash.
        let hasChanges = (self.navigationController as? FilePreviewNavigationController)?.hasChanges ?? false
        if let delegate = delegate {
            delegate.filePreviewNavigationControllerWillClose(self, hasChanges: hasChanges)
        } else {
            // No delegate wired — still ensure the modal closes rather than getting stuck.
            dismiss(animated: true)
        }
    }

    @objc private func onDidUpdateShares(_ notification: Notification) {
        if let shareLinkVM = notification.object as? ShareLinkViewModel,
           file.recordId == shareLinkVM.fileViewModel.recordId,
           file.folderLinkId == shareLinkVM.fileViewModel.folderLinkId {
            file.accessRole = shareLinkVM.fileViewModel.accessRole
            file.minArchiveVOS = shareLinkVM.fileViewModel.minArchiveVOS
            return
        }

        guard let updatedFileModel = notification.userInfo?["fileModel"] as? FileModel,
              file.recordId == updatedFileModel.recordId,
              file.folderLinkId == updatedFileModel.folderLinkId else {
            return
        }

        file.accessRole = updatedFileModel.accessRole
        file.minArchiveVOS = updatedFileModel.minArchiveVOS
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let collectionView = collectionView,
              let keyBoardInfo = notification.userInfo,
              let endFrame = keyBoardInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let window = collectionView.window
        else { return }
        
        let keyBoardFrame = window.convert(endFrame.cgRectValue, to: collectionView.superview)
        let newBottomInset = collectionView.frame.origin.y + collectionView.frame.size.height - keyBoardFrame.origin.y
        var tableInsets = collectionView.contentInset
        var scrollIndicatorInsets = collectionView.scrollIndicatorInsets
        let oldBottomInset = tableInsets.bottom
        if newBottomInset > oldBottomInset {
            tableInsets.bottom = newBottomInset
            scrollIndicatorInsets.bottom = tableInsets.bottom
            
            UIView.beginAnimations(nil, context: nil)
            UIView.setAnimationDuration((keyBoardInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double))
            UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: (keyBoardInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int))!)
            collectionView.contentInset = tableInsets
            collectionView.scrollIndicatorInsets = scrollIndicatorInsets
            UIView.commitAnimations()
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        let keyBoardInfo = notification.userInfo!
        var tableInsets = collectionView.contentInset
        var scrollIndicatorInsets = collectionView.scrollIndicatorInsets
        tableInsets.bottom = 0
        scrollIndicatorInsets.bottom = tableInsets.bottom
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration((keyBoardInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double))
        UIView.setAnimationCurve(UIView.AnimationCurve(rawValue: (keyBoardInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! Int))!)
        collectionView.contentInset = tableInsets
        collectionView.scrollIndicatorInsets = scrollIndicatorInsets
        UIView.commitAnimations()
    }

    private func share(url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // For iPad support
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true)
    }
    
    private func segmentedControlChangedAction() -> ((FileDetailsMenuCollectionViewCell) -> Void) {
        return { [weak self] cell in
            guard let strongSelf = self else { return }
            
            if cell.segmentedControl.selectedSegmentIndex == 0 {
                strongSelf.bottomSectionCells = [.name, .description, .date, .location, .tags]
            } else {
                strongSelf.bottomSectionCells = [.uploaded, .lastModified, .created, .fileCreated, .size, .fileType, .originalFileName, .originalFileType]
            }
            
            strongSelf.collectionView.reloadSections([1])
        }
    }
    
    @objc func onDidUpdateData(_ notification: Notification) {
        if let notifVM = notification.object as? FilePreviewViewModel, notifVM.file == viewModel?.file {
            self.title = viewModel?.name
            collectionView.reloadSections([1])
            view.showNotificationBanner(title: "Change was saved".localized())
        }
    }
    
    @objc func onFailedUpdateData(_ notification: Notification) {
        if let notifVM = notification.object as? FilePreviewViewModel, notifVM.file == viewModel?.file {
            view.showNotificationBanner(title: "Failed to save changes".localized(), backgroundColor: .deepRed, textColor: .white)
        }
    }
    
    func shareWithOtherApps() {
        // Check for file using displayName + extension (matches DownloadManagerGCD naming)
        let fileExtension = (file.uploadFileName as NSString).pathExtension
        let fileName = !fileExtension.isEmpty ? "\(file.name).\(fileExtension)" : file.name
        
        if let localURL = fileHelper.url(forFileNamed: FileHelper.recordScopedName(fileName, recordId: file.recordId)) {
            share(url: localURL)
        } else {
            let preparingAlert = UIAlertController(title: "Preparing File..".localized(), message: nil, preferredStyle: .alert)
            preparingAlert.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: { _ in
                self.viewModel?.cancelDownload()
            }))

            present(preparingAlert, animated: true) {
                if let record = self.viewModel?.recordVO {
                    self.viewModel?.download(record, fileType: self.file.type, onFileDownloaded: { url, _ in
                        if let url = url {
                            self.dismiss(animated: true) {
                                self.share(url: url)
                            }
                        } else {
                            self.dismiss(animated: true, completion: nil)
                        }
                    })
                }
            }
        }
    }
    
    func publishAction() {
        let presentPublishView: () -> Void = { [weak self] in
            guard let self = self else { return }
            
            var hostingController: UIHostingController<PublishView>?
            
            let publishView = PublishView(
                fileName: self.file.name,
                isFolder: self.file.type.isFolder,
                thumbnailURL: self.file.thumbnailURL,
                thumbnailURL2000: self.file.thumbnailURL2000,
                onPublish: { [weak self] in
                    hostingController?.dismiss(animated: false) {
                        self?.publish()
                    }
                },
                onDismiss: {
                    hostingController?.dismiss(animated: false)
                }
            )
            
            hostingController = UIHostingController(rootView: publishView)
            hostingController?.modalPresentationStyle = .overFullScreen
            hostingController?.modalTransitionStyle = .crossDissolve
            hostingController?.view.backgroundColor = .clear
            
            if let controller = hostingController {
                self.present(controller, animated: false)
            }
        }
        
        if let presented = presentedViewController {
            presented.dismiss(animated: true) {
                DispatchQueue.main.async {
                    presentPublishView()
                }
            }
        } else {
            presentPublishView()
        }
    }
    
    private func publish() {
        showSpinner()

        // Publish = copy the item into the public workspace root.
        let onPublishResult: (Error?) -> Void = { [weak self] error in
            guard let self = self else { return }
            self.hideSpinner()
            if let error = error {
                self.showErrorAlert(message: error.localizedDescription)
            } else {
                let title = self.file.type.isFolder ? "Folder published successfully".localized() : "File published successfully".localized()
                self.view.showNotificationBanner(height: Constants.Design.bannerHeight, title: title)
            }
        }

        // VSP-1787 sibling: an own-archive record that publishes via the V2 copy resolves its
        // public-workspace destination through the Stela archives search (no V1 getPublicRoot).
        // On ANY resolution failure, fall back to the V1 getPublicRoot destination lookup.
        if viewModel?.canPublishViaStelaCopy == true {
            viewModel?.resolvePublicRootFolderIdV2 { [weak self] publicRootFolderId in
                guard let self = self else { return }
                if let publicRootFolderId = publicRootFolderId {
                    self.viewModel?.copyRecordV2(destinationFolderId: publicRootFolderId, completion: onPublishResult)
                } else {
                    self.publishViaV1PublicRoot(onPublishResult: onPublishResult)
                }
            }
            return
        }

        publishViaV1PublicRoot(onPublishResult: onPublishResult)
    }

    /// Legacy destination lookup, kept as the failsafe for the V2 public-root path: V1
    /// getPublicRoot → V2 copyRecordV2 (own-archive records) or V1 relocate (folders /
    /// foreign records). A -1 destination folderId (getPublicRoot omitted folderID) routes
    /// to relocate rather than posting "-1".
    private func publishViaV1PublicRoot(onPublishResult: @escaping (Error?) -> Void) {
        guard let archiveNbr = AuthenticationManager.shared.session?.selectedArchive?.archiveNbr else {
            hideSpinner()
            showErrorAlert(message: "Unable to publish file")
            return
        }
        let filesRepository = FilesRepository()
        filesRepository.getPublicRoot(archiveNbr: archiveNbr) { [weak self] (folder, error) in
            guard let self = self else { return }
            if let error = error {
                self.hideSpinner()
                self.showErrorAlert(message: error.localizedDescription)
                return
            }
            guard let publicRootFolder = folder else {
                self.hideSpinner()
                self.showErrorAlert(message: "Unable to get public folder")
                return
            }
            if self.viewModel?.canPublishViaStelaCopy == true, publicRootFolder.folderId > 0 {
                self.viewModel?.copyRecordV2(destinationFolderId: String(publicRootFolder.folderId), completion: onPublishResult)
            } else {
                filesRepository.relocate(files: [self.file], folderLinkId: publicRootFolder.folderLinkId, isCopy: true, completion: onPublishResult)
            }
        }
    }

}

// MARK: - UICollectionViewDataSource
extension FileDetailsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return topSectionCells.count
        } else if section == 1 {
            return bottomSectionCells.count
        }
        
        return 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionCellTypes = indexPath.section == 0 ? topSectionCells : bottomSectionCells
        let currentCellType = sectionCellTypes[indexPath.item]
        
        let returnedCell: FileDetailsBaseCollectionViewCell
        
        switch currentCellType {
        case .thumbnail:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsTopCollectionViewCell.identifier, for: indexPath) as! FileDetailsTopCollectionViewCell
            
            returnedCell = cell
            
        case .segmentedControl:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsMenuCollectionViewCell.identifier, for: indexPath) as! FileDetailsMenuCollectionViewCell
            cell.segmentedControlAction = segmentedControlChangedAction()
            
            returnedCell = cell
            
        case .name, .description, .size, .fileType, .originalFileName, .originalFileType:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsBottomCollectionViewCell.identifier, for: indexPath) as! FileDetailsBottomCollectionViewCell

            returnedCell = cell

        case .location:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsMapViewCellCollectionViewCell.identifier, for: indexPath) as! FileDetailsMapViewCellCollectionViewCell
            
            returnedCell = cell
            
        case .tags:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TagsNamesCollectionViewCell.identifier, for: indexPath) as! TagsNamesCollectionViewCell
            
            returnedCell = cell
            
        case .date, .uploaded, .lastModified, .created, .fileCreated:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileDetailsDateCollectionViewCell.identifier, for: indexPath) as! FileDetailsDateCollectionViewCell
            
            returnedCell = cell
        }
        
        returnedCell.configure(withViewModel: viewModel!, type: currentCellType)
        
        return returnedCell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FileDetailsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let sectionCellTypes = indexPath.section == 0 ? topSectionCells : bottomSectionCells
        let currentCellType = sectionCellTypes[indexPath.item]
        
        if currentCellType == .thumbnail {
            dismiss(animated: false, completion: nil)
        }
        
        if currentCellType == .location && viewModel?.isEditable ?? false {
            let locationSetVC = UIViewController.create(withIdentifier: .locationSetOnTap, from: .main) as! LocationSetViewController
            locationSetVC.delegate = self
            locationSetVC.file = file
            locationSetVC.viewModel = viewModel
            
            let navigationVC = NavigationController(rootViewController: locationSetVC)
            navigationVC.modalPresentationStyle = .fullScreen
            present(navigationVC, animated: true)
        }
        
        if currentCellType == .tags && viewModel?.isEditable ?? false {
            let tagSetVC = UIViewController.create(withIdentifier: .tagDetails, from: .main) as! TagDetailsViewController
            tagSetVC.delegate = self
            tagSetVC.viewModel = viewModel

            let navigationVC = NavigationController(rootViewController: tagSetVC)
            navigationVC.modalPresentationStyle = .fullScreen
            present(navigationVC, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let sectionCellTypes = indexPath.section == 0 ? topSectionCells : bottomSectionCells
        let currentCellType = sectionCellTypes[indexPath.item]
        
        switch currentCellType {
        case .thumbnail:
            return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.45)
            
        case .segmentedControl:
            return CGSize(width: UIScreen.main.bounds.width, height: 40)
            
        case .location:
            if let _ = viewModel?.recordVO?.recordVO?.locnVO?.latitude,
               let _ = viewModel?.recordVO?.recordVO?.locnVO?.longitude {
                return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width * 0.65)
            } else {
                return CGSize(width: UIScreen.main.bounds.width, height: 65)
            }
            
        case .tags:
            /*
             | - ( tag1 ) - (tag 2) - (tag abc) - |
             | - (aaa) - (bbbv) - (cccc) - |
             | - (aaa) - (bbbv) - (cccc) - |
             */
            
            // Title label height + bottom spacing
            let tagLabelCellHeight: CGFloat = 30
            let tagCellHeight: CGFloat = 35
            let collectionViewWidthConstrains: CGFloat = 45.0
            
            // See TagsNamesCollectionViewCell for more info. 20 extra spacing in chip + 5 interitem spacing.
            let tagAdditionalSpacing: CGFloat = 20 + 5
            
            let tagsName: [String] = viewModel?.recordVO?.recordVO?.tagVOS?.compactMap { $0.name } ?? []
            
            let tagsWidth = tagsName.map {
                NSAttributedString(string: $0, attributes: [NSAttributedString.Key.font: TextFontStyle.style8.font as Any])
            }.map {
                $0.boundingRect(with: CGSize(width: collectionView.bounds.width, height: 30), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).size.width.rounded(.up) + tagAdditionalSpacing
            }
            
            var currentRowWidth: CGFloat = 0
            var currentRowCount: Int = 0
            tagsWidth.forEach { (width) in
                if currentRowWidth + width > (view.frame.width - collectionViewWidthConstrains) {
                    currentRowWidth = width
                    currentRowCount += 1
                } else {
                    if currentRowCount == 0 {
                        currentRowCount += 1
                    }
                    currentRowWidth += width
                }
            }
            //Set tags cell height in regard with screen width and total tag cells width
            let cellHeightByTagsWidth :CGFloat = currentRowCount != 0 ? tagLabelCellHeight + CGFloat(currentRowCount) * tagCellHeight : tagLabelCellHeight + tagCellHeight
            
            return CGSize(width: UIScreen.main.bounds.width, height: cellHeightByTagsWidth)
        default:
            return CGSize(width: UIScreen.main.bounds.width, height: 65)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 5, right: 0)
    }
}

// MARK: - LocationSetViewControllerDelegate
extension FileDetailsViewController: LocationSetViewControllerDelegate {
    func locationSetViewControllerDidUpdate(_ locationVC: LocationSetViewController) {
        collectionView.reloadSections([1])
    }
}

// MARK: - TagDetailsViewControllerDelegate
extension FileDetailsViewController: TagDetailsViewControllerDelegate {
    func tagDetailsViewControllerDidUpdate(_ tagVC: TagDetailsViewController) {
        collectionView.reloadSections([1])
    }
}
