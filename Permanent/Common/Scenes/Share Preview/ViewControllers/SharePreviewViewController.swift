//
//  SharePreviewViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 08.01.2021.
//

import UIKit

class SharePreviewViewController: UIViewController {
    // MARK: - Properties
    
    @IBOutlet var archiveImage: UIImageView!
    @IBOutlet var headerView: UIView!
    @IBOutlet var shareNameLabel: UILabel!
    @IBOutlet var archiveNameLabel: UILabel!
    @IBOutlet var sharedByLabel: UILabel!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var actionButton: RoundedButton!
    
    @IBOutlet weak var currentArchiveContainer: UIView!
    @IBOutlet weak var currentArchiveImageView: UIImageView!
    @IBOutlet weak var currentArchiveName: UILabel!
    @IBOutlet weak var currentArchiveDefaultButton: UIButton!
    @IBOutlet weak var selectArchiveLabel: UILabel!
    
    @IBOutlet weak var headerViewCollectionConstrain: NSLayoutConstraint!
    
    var viewModel: SharePreviewViewModelDelegate! {
        didSet {
            viewModel.viewDelegate = self
        }
    }
    
    var navigateTo: ((NavigateMinParams) -> Void) = { _ in }
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
    
        configureUI()
        setupCollectionView()
        viewModel.start()
    }

    fileprivate func configureUI() {
        navigationItem.title = .sharePreview
        view.backgroundColor = .galleryGray
     
        // MARK: Shared by view setup
        headerView.backgroundColor = .backgroundPrimary
        collectionView.backgroundColor = .backgroundPrimary
        
        shareNameLabel.textColor = .black
        shareNameLabel.font = TextFontStyle.style18.font
        
        sharedByLabel.textColor = .textPrimary
        sharedByLabel.font = TextFontStyle.style12.font
        
        archiveNameLabel.textColor = .textPrimary
        archiveNameLabel.font = TextFontStyle.style19.font
        
        archiveImage.backgroundColor = .primary
        archiveImage.clipsToBounds = true
        archiveImage.layer.cornerRadius = 30
        
        archiveImage.isHidden = true
        actionButton.isHidden = true
        
        // MARK: Current Archive view setup
        currentArchiveContainer.layer.borderWidth = 1
        currentArchiveContainer.layer.borderColor = UIColor.darkBlue.cgColor
        currentArchiveContainer.layer.cornerRadius = Constants.Design.actionButtonRadius
        currentArchiveContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(changeArchiveButtonPressed(_:))))
        
        currentArchiveName.text = nil
        currentArchiveName.font = TextFontStyle.style17.font
        currentArchiveName.textColor = .darkBlue
        
        selectArchiveLabel.text = "Tap to change archive".localized()
        selectArchiveLabel.font = TextFontStyle.style7.font
        selectArchiveLabel.textColor = .darkBlue
        
        updateCurrentArchiveView()
    }
    
    func updateCurrentArchiveView() {
        if let archiveThumbURL = viewModel.currentArchive?.thumbURL500,
           let archiveName = viewModel.currentArchive?.fullName {
            currentArchiveImageView.image = nil
            currentArchiveImageView.load(urlString: archiveThumbURL)
            
            currentArchiveDefaultButton.isHidden = viewModel.currentArchive?.archiveID != AuthenticationManager.shared.session?.account.defaultArchiveID
            
            currentArchiveName.text = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
        }
        
        viewModel.updateAccountArchives { [self] in
            if let accountArchives = viewModel.accountArchives,
                accountArchives.count == 1 {
                currentArchiveContainer.isHidden = true
            }
        }
    }
    
    fileprivate func setupCollectionView() {
        collectionView.register(UINib(nibName: FileLargeCollectionViewCell.reuseIdentifier, bundle: nil),
                                forCellWithReuseIdentifier: FileLargeCollectionViewCell.reuseIdentifier)
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.sectionInset = UIEdgeInsets(top: 5, left: 2, bottom: 5, right: 2)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        collectionView.collectionViewLayout = flowLayout
    }
    
    fileprivate func setupActionButton(forStatus status: ShareStatus) {
        // Check if current user is the share creator
        let isShareCreator = isCurrentUserShareCreator()
        
        switch status {
        case .pending:
            // If user is the creator, they should be able to view their own share
            if isShareCreator {
                actionButton.configureActionButtonUI(title: viewModel.navigateParams == nil ? .viewInArchive : .viewInArchive)
            } else {
                actionButton.isEnabled = false
                actionButton.titleLabel?.adjustsFontSizeToFitWidth = true
                actionButton.setTitleColor(.primary, for: [])
                actionButton.configureActionButtonUI(title: status.infoText, bgColor: .backgroundPrimary)
            }
            
        case .needsApproval:
            // If user is the creator, they shouldn't need to request approval
            if isShareCreator {
                actionButton.configureActionButtonUI(title: viewModel.navigateParams == nil ? .viewInArchive : .viewInArchive)
            } else {
                actionButton.configureActionButtonUI(title: viewModel.navigateParams == nil ? status.infoText : .viewInArchive)
            }
            
        default:
            actionButton.configureActionButtonUI(title: viewModel.navigateParams == nil ? status.infoText : .viewInArchive)
        }
        
        actionButton.isHidden = false
    }
    
    // MARK: - Helper Methods
    
    /// Checks if the current user is the creator of the share
    private func isCurrentUserShareCreator() -> Bool {
        guard let currentUserAccountId = AuthenticationManager.shared.session?.account.accountID else {
            return false
        }
        
        // Primary check: Use the creator account ID stored in ShareDetailsVM
        if let shareDetailsVM = viewModel.shareDetails as? ShareDetailsVM,
           let creatorAccountId = shareDetailsVM.creatorAccountId {
            return creatorAccountId == currentUserAccountId
        }
        
        // Fallback check: Use navigateParams which is set in the ViewModel when current user is the creator
        // This is set in SharePreviewViewModel.onFetchSharedItemsSuccess when the share creator email
        // matches the current user email
        if viewModel.navigateParams != nil {
            return true
        }
        
        return false
    }
    
    /// Fallback method to navigate to shared folder when navigateParams is not available
    private func navigateToSharedFolder() {
        guard let shareDetails = viewModel?.shareDetails,
              let currentArchive = viewModel?.currentArchive else {
            // Fallback to shares view if we can't get the necessary data
            viewInArchive()
            return
        }
        
        // Check if the currently selected archive matches the original archive where the share was created
        let currentArchiveNbr = currentArchive.archiveNbr ?? ""
        let originalArchiveNbr = shareDetails.originalArchiveNbr ?? ""
        
        if !originalArchiveNbr.isEmpty && currentArchiveNbr != originalArchiveNbr {
            showArchiveMismatchAlert(correctArchiveName: shareDetails.cleanArchiveName ?? shareDetails.archiveName)
            return
        }
        
        // Try to construct navigation parameters from available data
        let archiveNo = currentArchive.archiveNbr ?? ""
        
        // Check if this is a folder share (we can navigate directly)
        if let fileType = shareDetails.fileType, fileType == .publicFolder {
            let folderLinkId = shareDetails.folderLinkId
            let folderName = shareDetails.sharedFileName
            
            if !archiveNo.isEmpty && folderLinkId > 0 {
                let params: NavigateMinParams = (archiveNo: archiveNo, folderLinkId: folderLinkId, folderName: folderName)
                DispatchQueue.main.async { [weak self] in
                    self?.navigateTo(params)
                }
                return
            }
        }
        
        // For file shares, try to navigate to the parent folder using parentFolderLinkId
        if let shareDetailsVM = shareDetails as? ShareDetailsVM,
           let parentFolderLinkId = shareDetailsVM.parentFolderLinkId,
           !archiveNo.isEmpty && parentFolderLinkId > 0 {
            
            let params: NavigateMinParams = (archiveNo: archiveNo, folderLinkId: parentFolderLinkId, folderName: "Containing Folder")
            DispatchQueue.main.async { [weak self] in
                self?.navigateTo(params)
            }
            return
        }
        
        // Fallback to viewInArchive as last resort
        viewInArchive()
    }
    
    // MARK: - Actions
    
    @IBAction func previewAction(_ sender: UIButton) {
        // Add safety check to prevent any potential issues
        guard let viewModel = viewModel else {
            return
        }
        
        // Check if the currently selected archive matches the original archive where the share was created
        if let shareDetails = viewModel.shareDetails,
           let currentArchive = viewModel.currentArchive {
            let currentArchiveNbr = currentArchive.archiveNbr ?? ""
            let originalArchiveNbr = shareDetails.originalArchiveNbr ?? ""
            
            if !originalArchiveNbr.isEmpty && currentArchiveNbr != originalArchiveNbr {
                showArchiveMismatchAlert(correctArchiveName: shareDetails.cleanArchiveName ?? shareDetails.archiveName)
                return
            }
        }
        
        let isShareCreator = isCurrentUserShareCreator()
        
        if isShareCreator {
            // If user is the share creator, navigate directly to the folder without back navigation
            if let params = viewModel.navigateParams {
                // Use the existing navigation params to go to the folder directly
                DispatchQueue.main.async { [weak self] in
                    self?.navigateTo(params)
                }
            } else {
                // Fallback: try to construct navigation params from share details
                navigateToSharedFolder()
            }
        } else {
            // For non-creators, use the standard flow based on status
            if viewModel.navigateParams == nil {
                viewModel.performAction()
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                    if let params = viewModel.navigateParams {
                        self?.navigateTo(params)
                    }
                }
            }
        }
    }
    
    @IBAction func changeArchiveButtonPressed(_ sender: Any) {
        let archivesVC = UIViewController.create(withIdentifier: .archives, from: .archives) as! ArchivesViewController
        archivesVC.delegate = self
        archivesVC.isManaging = false
        archivesVC.accountArchives = self.viewModel.accountArchives
        
        let navController = NavigationController(rootViewController: archivesVC)
        present(navController, animated: true, completion: nil)
    }
    
    @objc
    fileprivate func dismissScreen() {
        navigationController?.popViewController(animated: true)
    }
    
    /// Shows an alert when the user has selected the wrong archive
    private func showArchiveMismatchAlert(correctArchiveName: String) {
        let alert = UIAlertController(
            title: "Incorrect Archive",
            message: "This item is shared from '\(correctArchiveName)'. You need to select the correct archive to view this content.",
            preferredStyle: .alert
        )
        
        // Add action to change archive
        alert.addAction(UIAlertAction(title: "Change Archive", style: .default) { [weak self] _ in
            self?.changeArchiveButtonPressed(self?.actionButton as Any)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - UICollectionView Delegates

extension SharePreviewViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: FileLargeCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? FileLargeCollectionViewCell else {
            fatalError()
        }
        
        cell.file = viewModel.itemFor(row: indexPath.row)
        cell.details = viewModel.shareDetails
        
        return cell
    }
}

extension SharePreviewViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let noOfCellsInRow = Constants.Design.numberOfGridItemsPerRow
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        
        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))
        
        let size = Int((collectionView.bounds.width - totalSpace) / CGFloat(noOfCellsInRow))
        
        return CGSize(width: size, height: size)
    }
}

// MARK: ViewModel Delegate

extension SharePreviewViewController: SharePreviewViewModelViewDelegate {
    func updateShareAccess(status: RequestStatus, shareStatus: ShareStatus?) {
        switch status {
        case .success:
            if let shareStatus = shareStatus {
                setupActionButton(forStatus: shareStatus)
                collectionView.reloadData()
            }
            
        case .error(_):
            break
        }
    }
    
    func updateScreen(status: RequestStatus, shareDetails: ShareDetails?) {
        switch status {
        case .success:
            collectionView.reloadData()
            
            if let details = shareDetails {
                // Header setup
                shareNameLabel.text = details.sharedFileName
                archiveNameLabel.text = details.archiveName
                sharedByLabel.text = details.accountName
                
                // Load archive thumbnail with better error handling
                if let archiveThumbURL = details.archiveThumbURL {
                    archiveImage.sd_setImage(with: archiveThumbURL, placeholderImage: nil) { [weak self] image, error, _, _ in
                        if error != nil {
                            // If there's an error loading the thumbnail, try to use a default archive icon
                            self?.archiveImage.image = UIImage(named: "archiveThumb") ?? UIImage(systemName: "folder.fill")
                        }
                    }
                } else {
                    // No thumbnail URL available, use default
                    archiveImage.image = UIImage(named: "archiveThumb") ?? UIImage(systemName: "folder.fill")
                }
                archiveImage.isHidden = false
                
                setupActionButton(forStatus: details.status)
            }
            
        case .error:
            headerViewCollectionConstrain.constant = .zero
            actionButton.isHidden = true
            currentArchiveContainer.isHidden = true
            actionButton.configureActionButtonUI(title: .ok)
            actionButton.addTarget(self, action: #selector(dismissScreen), for: .touchUpInside)
            
            let emptyView = EmptyFolderView(title: .linkNotAvailable, image: .chicken)
            emptyView.frame = collectionView.bounds
            collectionView.backgroundView = emptyView
        }
    }
    
    func updateSpinner(isLoading: Bool) {
        isLoading ? showSpinner() : hideSpinner()
    }
    
    func viewInArchive() {
        let isShareCreator = isCurrentUserShareCreator()
        
        if isShareCreator {
            // For share creators, navigate to the actual location in their private archive
            guard let shareDetails = viewModel?.shareDetails,
                  let currentArchive = viewModel?.currentArchive else {
                return
            }
            
            let archiveNo = currentArchive.archiveNbr ?? ""
            
            // Check if this is a folder share
            if let fileType = shareDetails.fileType, fileType == .publicFolder {
                let folderLinkId = shareDetails.folderLinkId
                let folderName = shareDetails.sharedFileName
                
                if !archiveNo.isEmpty && folderLinkId > 0 {
                    let params: NavigateMinParams = (archiveNo: archiveNo, folderLinkId: folderLinkId, folderName: folderName)
                    DispatchQueue.main.async { [weak self] in
                        self?.navigateTo(params)
                    }
                    return
                }
            }
            
            // For file shares, navigate to the parent folder using parentFolderLinkId
            if let shareDetailsVM = shareDetails as? ShareDetailsVM,
               let parentFolderLinkId = shareDetailsVM.parentFolderLinkId,
               !archiveNo.isEmpty && parentFolderLinkId > 0 {
                
                let params: NavigateMinParams = (archiveNo: archiveNo, folderLinkId: parentFolderLinkId, folderName: "Containing Folder")
                DispatchQueue.main.async { [weak self] in
                    self?.navigateTo(params)
                }
                return
            }
            
            // Fallback: navigate to the main files view if we can't determine the specific location
            DispatchQueue.main.async {
                let mainVC = UIViewController.create(withIdentifier: .main, from: .main) as! MainViewController
                mainVC.viewModel = MyFilesViewModel()
                AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: mainVC)
            }
        } else {
            // For non-creators, show the shares list
            guard let sharesVC = UIViewController.create(
                withIdentifier: .shares,
                from: .share
            ) as? SharesViewController else {
                return
            }
            
            // Set only the basic information needed for the shares view
            sharesVC.sharedFolderArchiveNo = viewModel.currentArchive?.archiveNbr ?? ""
            sharesVC.selectedIndex = ShareListType.sharedWithMe.rawValue
            
            AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: sharesVC)
        }
    }
}

extension SharePreviewViewController: ArchivesViewControllerDelegate {
    func archivesViewControllerDidChangeArchive(_ vc: ArchivesViewController) {
        updateCurrentArchiveView()
        viewModel.start()
    }
}
