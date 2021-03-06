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
    
    var viewModel: SharePreviewViewModelDelegate! {
        didSet {
            viewModel.viewDelegate = self
        }
    }
    
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
     
        headerView.backgroundColor = .backgroundPrimary
        collectionView.backgroundColor = .backgroundPrimary
        
        shareNameLabel.textColor = .black
        shareNameLabel.font = Text.style18.font
        
        sharedByLabel.textColor = .textPrimary
        sharedByLabel.font = Text.style12.font
        
        archiveNameLabel.textColor = .textPrimary
        archiveNameLabel.font = Text.style19.font
        
        archiveImage.backgroundColor = .primary
        archiveImage.clipsToBounds = true
        archiveImage.layer.cornerRadius = 30
        
        archiveImage.isHidden = true
        actionButton.isHidden = true
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
        switch status {
        case .pending:
            actionButton.isEnabled = false
            actionButton.titleLabel?.adjustsFontSizeToFitWidth = true
            actionButton.setTitleColor(.primary, for: [])
            actionButton.configureActionButtonUI(title: status.infoText, bgColor: .backgroundPrimary)
            
        default:
            actionButton.configureActionButtonUI(title: status.infoText)
        }
        
        actionButton.isHidden = false
    }
    
    // MARK: - Actions
    
    @IBAction func previewAction(_ sender: UIButton) {
        viewModel.performAction()
    }
    
    @objc
    fileprivate func dismissScreen() {
        navigationController?.popViewController(animated: true)
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
            
        case .error(let message):
            print(message)
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
                archiveImage.sd_setImage(with: details.archiveThumbURL)
                archiveImage.isHidden = false
                
                setupActionButton(forStatus: details.status)
            }
            
        case .error:
            actionButton.isHidden = false
            actionButton.configureActionButtonUI(title: .ok)
            actionButton.addTarget(self, action: #selector(dismissScreen), for: .touchUpInside)
            collectionView.backgroundView = EmptyFolderView(
                title: .linkNotAvailable,
                image: .chicken
            )
        }
    }
    
    func updateSpinner(isLoading: Bool) {
        isLoading ? showSpinner() : hideSpinner()
    }
    
    func viewInArchive() {
        guard let sharesVC = UIViewController.create(
            withIdentifier: .shares,
            from: .share
        ) as? SharesViewController else {
            return
        }
        
        sharesVC.selectedIndex = ShareListType.sharedWithMe.rawValue
        sharesVC.selectedFileId = viewModel.shareDetails?.folderLinkId
        AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: sharesVC)
    }
}
