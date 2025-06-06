//
//  PublicArchiveViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 01.12.2021.
//

import UIKit

protocol PublicArchiveChildDelegate: AnyObject {
    /// - Parameter vc: the child view controller
    /// - Parameter offset: the child scrollView offset after scrolling
    /// - Returns: true if the offset was handled by the parent and the child has to reset it's offset
    func childVC(_ vc: UIViewController, didScrollToOffset offset: CGPoint) -> Bool
}

class PublicArchiveViewController: BaseViewController<PublicProfilePicturesViewModel> {
    @IBOutlet weak var headerContainerView: UIView!
    @IBOutlet weak var headerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var collectionViewContainer: UIView!
    
    @IBOutlet weak var profileBannerImageView: UIImageView!
    @IBOutlet weak var changeProfileBannerButton: UIButton!
    @IBOutlet weak var profilePhotoImageView: UIImageView!
    @IBOutlet weak var changeProfilePhotoButton: UIButton!
    @IBOutlet weak var changeProfileBannerPhotoButtonView: UIView!
    @IBOutlet weak var changeProfilePhotoButtonView: UIView!
    @IBOutlet weak var profilePhotoBorderView: UIView!
    
    var archiveData: ArchiveVOData!
    var archiveNbr: String?
    var deeplinkPayload: PublicProfileDeeplinkPayload?
    
    var profilePageVC: PublicProfilePageViewController!
    var archiveVC: PublicArchiveFileViewController!
    
    var isPickingProfilePicture: Bool = false
    var isViewingPublicProfile: Bool = false
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = PublicProfilePicturesViewModel()
        
        // Listen for archive name changes to update title
        NotificationCenter.default.addObserver(forName: Notification.Name("ArchivesViewModel.didChangeArchiveNotification"), object: nil, queue: .main) { [weak self] _ in
            self?.handleArchiveNameUpdate()
        }
        
        if archiveData == nil {
            showSpinner()

            if archiveNbr == nil {
                archiveNbr = deeplinkPayload?.archiveNbr
            }

            viewModel?.getPublicArchive(withArchiveNbr: archiveNbr!, {[weak self] archiveVOData in
                guard let archiveVOData = archiveVOData else {
                    self?.showErrorAlert(message: "Something went wrong, please try again!")
                    return
                }
                self?.hideSpinner()
                self?.archiveData = archiveVOData
                self?.initUI()
            })
        } else {
            initUI()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reset header to fully visible state
        headerViewTopConstraint.constant = 0
        
        // Reset child scroll views to top
        if let profilePageVC = profilePageVC, profilePageVC.isViewLoaded {
            profilePageVC.collectionView.setContentOffset(.zero, animated: false)
        }
        
        if let archiveVC = archiveVC, archiveVC.isViewLoaded {
            archiveVC.collectionView.setContentOffset(.zero, animated: false)
        }
        
        // Force layout update
        view.layoutIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Ensure header is in the correct initial state
        if headerViewTopConstraint.constant != 0 {
            headerViewTopConstraint.constant = 0
            view.layoutIfNeeded()
        }
    }

    func initUI() {
        viewModel?.archiveData = archiveData
        
        if let archiveName = archiveData.fullName {
            title = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
        }
        
        if navigationController?.presentingViewController != nil {
            let leftButtonImage: UIImage!
            leftButtonImage = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: leftButtonImage, style: .plain, target: self, action: #selector(closeButtonAction(_:)))
        }
        
        if viewModel?.canEditPublicProfilePhoto() == true {
            changeProfilePhotoButton.isHidden = true
            changeProfilePhotoButtonView.alpha = 0
            changeProfileBannerPhotoButtonView.alpha = 0
            changeProfileBannerButton.isHidden = true
        }
        
        profilePageVC = UIViewController.create(withIdentifier: .profilePage, from: .profile) as? PublicProfilePageViewController
        profilePageVC.delegate = self
        profilePageVC.archiveData = archiveData
        addChild(profilePageVC)
        profilePageVC.view.frame = collectionViewContainer.bounds
        profilePageVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionViewContainer.addSubview(profilePageVC.view)
        profilePageVC.didMove(toParent: self)
        profilePageVC.view.isHidden = isViewingPublicProfile ? false : true
        
        archiveVC = UIViewController.create(withIdentifier: .publicArchiveFileBrowser, from: .profile) as? PublicArchiveFileViewController
        archiveVC.delegate = self
        archiveVC.archiveData = archiveData
        archiveVC.deeplinkPayload = deeplinkPayload
        addChild(archiveVC)
        archiveVC.view.frame = collectionViewContainer.bounds
        archiveVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionViewContainer.addSubview(archiveVC.view)
        archiveVC.didMove(toParent: self)
        archiveVC.view.isHidden = isViewingPublicProfile ? true : false
        
        segmentedControl.selectedSegmentIndex = isViewingPublicProfile ? 1 : 0
        
        setupHeaderView()
    }
    
    func setupHeaderView() {
        profileBannerImageView.backgroundColor = .lightGray
        profilePhotoImageView.backgroundColor = .darkGray
        
        changeProfileBannerButton.setImage(UIImage(named: "cameraIcon")!, for: .normal)
        changeProfileBannerButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        changeProfileBannerButton.tintColor = .primary

        changeProfileBannerPhotoButtonView.backgroundColor = .galleryGray
        changeProfileBannerPhotoButtonView.clipsToBounds = true
        changeProfileBannerPhotoButtonView.layer.cornerRadius = changeProfileBannerPhotoButtonView.frame.width / 2
        changeProfileBannerPhotoButtonView.layer.borderColor = UIColor.white.cgColor
        changeProfileBannerPhotoButtonView.layer.borderWidth = 1
        changeProfileBannerPhotoButtonView.isHidden = true
        
        changeProfilePhotoButton.setImage(UIImage(named: "cameraIcon")!, for: .normal)
        changeProfilePhotoButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        changeProfilePhotoButton.tintColor = .primary
        
        changeProfilePhotoButtonView.backgroundColor = .galleryGray
        changeProfilePhotoButtonView.clipsToBounds = true
        changeProfilePhotoButtonView.layer.cornerRadius = changeProfilePhotoButtonView.frame.width / 2
        changeProfilePhotoButtonView.layer.borderColor = UIColor.white.cgColor
        changeProfilePhotoButtonView.layer.borderWidth = 1
        changeProfilePhotoButtonView.isHidden = true
        
        profilePhotoBorderView.layer.cornerRadius = 2
        profilePhotoImageView.layer.cornerRadius = 2
        
        if let archiveThumb200 = archiveData.thumbURL200 {
            profilePhotoImageView.sd_setImage(with: URL(string: archiveThumb200))
        } else {
            profilePhotoImageView.image = UIColor.lightGray.imageWithColor(width: 48, height: 48)
        }
        
        
        viewModel?.getPublicRoot(then: { status in
            if status == .success, let bannerURL = self.viewModel?.bannerURL {
                self.profileBannerImageView.sd_setImage(with: bannerURL)
            }
            
            self.changeProfilePhotoButtonView.isHidden = false
            self.changeProfileBannerPhotoButtonView.isHidden = false
        })

        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: TextFontStyle.style11.font], for: .selected)
        segmentedControl.setTitleTextAttributes([.font: TextFontStyle.style8.font], for: .normal)
        segmentedControl.selectedSegmentTintColor = .primary
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        if segmentedControl.selectedSegmentIndex == 0 {
            profilePageVC.view.isHidden = true
            archiveVC.view.isHidden = false
            archiveVC.collectionView.contentOffset.y = 0
        } else {
            archiveVC.view.isHidden = true
            profilePageVC.view.isHidden = false
            profilePageVC.collectionView.contentOffset.y = 0
        }
    }
    
    @IBAction func changeBannerButtonPressed(_ sender: Any) {
        isPickingProfilePicture = false
        
        let myFilesVC = UIViewController.create(withIdentifier: .main, from: .main) as! MainViewController
        let myFilesVM = MyFilesViewModel()
        myFilesVM.isPickingImage = true
        myFilesVM.pickerDelegate = self
        myFilesVC.viewModel = myFilesVM
        
        let navigationController = NavigationController(rootViewController: myFilesVC)
        
        present(navigationController, animated: true, completion: nil)
    }
    
    @IBAction func changeProfileButtonPressed(_ sender: Any) {
        isPickingProfilePicture = true
        
        let myFilesVC = UIViewController.create(withIdentifier: .main, from: .main) as! MainViewController
        let myFilesVM = MyFilesViewModel()
        myFilesVM.isPickingImage = true
        myFilesVM.pickerDelegate = self
        myFilesVC.viewModel = myFilesVM
        
        let navigationController = NavigationController(rootViewController: myFilesVC)
        
        present(navigationController, animated: true, completion: nil)
    }
    
    @objc func closeButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    func handleArchiveNameUpdate() {
        // Called when user switches their selected archive (full archive change)
        // This triggers a complete refresh with scroll to top
        if let updatedArchiveName = AuthenticationManager.shared.session?.selectedArchive?.fullName {
            let newTitle = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: updatedArchiveName)
            self.title = newTitle
            
            // Update local archiveData to keep it in sync
            if let updatedArchive = AuthenticationManager.shared.session?.selectedArchive {
                self.archiveData = updatedArchive
                self.viewModel?.archiveData = updatedArchive
                
                // Update child view controllers with new archive data
                self.profilePageVC?.archiveData = updatedArchive
                self.profilePageVC?.viewModel?.archiveData = updatedArchive
                self.archiveVC?.archiveData = updatedArchive
                
                // Refresh the profile page data to prevent collection view crashes
                DispatchQueue.main.async { [weak self] in
                    if let profilePageVC = self?.profilePageVC, profilePageVC.isViewLoaded {
                        profilePageVC.handleArchiveChange(newArchiveData: updatedArchive)
                    }
                    
                    // Scroll both views to top for new archive content
                    self?.scrollChildViewsToTop()
                }
                
                // Update header view (banner and profile photos) for new archive
                updateHeaderForNewArchive(updatedArchive)
            }
        }
    }
    
    private func updateHeaderForNewArchive(_ newArchiveData: ArchiveVOData) {
        // Update profile photo from new archive data
        if let archiveThumb200 = newArchiveData.thumbURL200 {
            profilePhotoImageView.sd_setImage(with: URL(string: archiveThumb200))
        } else {
            profilePhotoImageView.image = UIColor.lightGray.imageWithColor(width: 48, height: 48)
        }
        
        // Refresh banner image for new archive
        viewModel?.getPublicRoot(then: { [weak self] status in
            if status == .success, let bannerURL = self?.viewModel?.bannerURL {
                self?.profileBannerImageView.sd_setImage(with: bannerURL)
            }
        })
    }
    
    private func scrollChildViewsToTop() {
        // Scroll profile page to top
        if let profilePageVC = profilePageVC, profilePageVC.isViewLoaded {
            profilePageVC.collectionView.setContentOffset(.zero, animated: false)
        }
        
        // Scroll archive file browser to top
        if let archiveVC = archiveVC, archiveVC.isViewLoaded {
            archiveVC.collectionView.setContentOffset(.zero, animated: false)
        }
        
        // Also reset the header scroll position
        headerViewTopConstraint.constant = 0
    }
    
    func handleLocalArchiveDataUpdate(_ updatedArchive: ArchiveVOData) {
        // Called when current archive's profile data is updated (local changes only)
        // Updates UI without scrolling or session changes
        
        // Update title with new archive name
        let newTitle = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: updatedArchive.fullName ?? "")
        self.title = newTitle
        
        // Update local archiveData to keep it in sync
        self.archiveData = updatedArchive
        self.viewModel?.archiveData = updatedArchive
        
        // Update child view controllers with new archive data
        self.profilePageVC?.archiveData = updatedArchive
        self.profilePageVC?.viewModel?.archiveData = updatedArchive
        self.archiveVC?.archiveData = updatedArchive
        
        // Ensure edit permissions are recalculated for the updated archive
        if let profilePageVC = self.profilePageVC,
           let isEditDataEnabled = profilePageVC.viewModel?.isEditDataEnabled {
            profilePageVC.isEditDataEnabled = isEditDataEnabled
            
            // Refresh the collection view to reflect the new edit state
            DispatchQueue.main.async {
                profilePageVC.collectionView.reloadData()
            }
        }
        
        // Update header view (banner and profile photos) for updated archive
        updateHeaderForNewArchive(updatedArchive)
        
        // No need to scroll to top or fully refresh for local data updates
    }
}

extension PublicArchiveViewController: PublicArchiveChildDelegate {
    func childVC(_ vc: UIViewController, didScrollToOffset offset: CGPoint) -> Bool {
        // Safety checks - ensure view is properly initialized
        guard isViewLoaded,
              headerViewTopConstraint != nil,
              headerContainerView != nil else {
            return false
        }
        
        let currentHeaderOffset = -headerViewTopConstraint.constant
        let maxHeaderOffset = headerContainerView.bounds.height
        
        // Ensure we have valid bounds
        guard maxHeaderOffset > 0 else {
            return false
        }
        
        // Scrolling UP - always try to reveal header first if it's hidden
        if offset.y < 0 {
            if currentHeaderOffset > 0 {
                // Header is hidden, reveal it first
                headerViewTopConstraint.constant -= offset.y
                
                // Clamp to fully visible
                if headerViewTopConstraint.constant > 0 {
                    headerViewTopConstraint.constant = 0
                }
                
                return true
            }
            // Header is fully visible, let child handle scroll
            return false
        }
        
        // Scrolling DOWN - always try to hide header first if it's visible
        if offset.y > 0 {
            if currentHeaderOffset < maxHeaderOffset {
                // Header is visible, hide it first
                headerViewTopConstraint.constant -= offset.y
                
                // Clamp to fully hidden
                if -headerViewTopConstraint.constant > maxHeaderOffset {
                    headerViewTopConstraint.constant = -maxHeaderOffset
                }
                
                return true
            }
            // Header is fully hidden, let child handle scroll
            return false
        }
        
        // No scroll or zero offset
        return false
    }
}

// MARK: - MyFilesViewModelPickerDelegate
extension PublicArchiveViewController: MyFilesViewModelPickerDelegate {
    func myFilesVMDidPickFile(viewModel: MyFilesViewModel, file: FileModel) {
        dismiss(animated: true) {
            var alertDescription: String = "Please wait while your banner is updated."
            if self.isPickingProfilePicture {
                alertDescription = "Please wait while your profile picture is updated."
            }
            let alert = UIAlertController(title: "Updating...", message: alertDescription, preferredStyle: .alert)
            self.present(alert, animated: true, completion: {
                if self.isPickingProfilePicture {
                    self.viewModel?.updateProfilePicture(file: file, then: { status in
                        self.dismiss(animated: true, completion: {
                            if status == .success, let thumbURL = URL(string: file.thumbnailURL2000) {
                                self.profilePhotoImageView.sd_setImage(with: thumbURL)
                                AuthenticationManager.shared.syncSession { [weak self] status in
                                    switch status {
                                    case .success:
                                        self?.profilePhotoImageView.sd_setImage(with: thumbURL)
                                    case .error(message: _):
                                        self?.showErrorAlert(message: .errorMessage)
                                    }
                                }
                            } else {
                                self.showErrorAlert(message: .errorMessage)
                            }
                        })
                    })
                } else {
                    self.viewModel?.updateBanner(thumbArchiveNbr: file.archiveNo, then: { status in
                        self.dismiss(animated: true, completion: {
                            if status == .success, let thumbURL = URL(string: file.thumbnailURL2000) {
                                self.profileBannerImageView.sd_setImage(with: thumbURL)
                            } else {
                                self.showErrorAlert(message: .errorMessage)
                            }
                        })
                    })
                }
            })
        }
    }
}
