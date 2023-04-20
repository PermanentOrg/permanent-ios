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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = PublicProfilePicturesViewModel()
        
        if archiveData == nil {
            showSpinner()

            if archiveNbr == nil {
                archiveNbr = deeplinkPayload?.archiveNbr
            }

            viewModel?.getPublicArchive(withArchiveNbr: archiveNbr!, { archiveVOData in
                self.hideSpinner()
                self.archiveData = archiveVOData
                self.initUI()
            })
        } else {
            initUI()
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
        profilePhotoImageView.sd_setImage(with: URL(string: archiveData.thumbURL200!))
        
        viewModel?.getPublicRoot(then: { status in
            if status == .success, let bannerURL = self.viewModel?.bannerURL {
                self.profileBannerImageView.sd_setImage(with: bannerURL)
            }
            
            self.changeProfilePhotoButtonView.isHidden = false
            self.changeProfileBannerPhotoButtonView.isHidden = false
        })

        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: Text.style11.font], for: .selected)
        segmentedControl.setTitleTextAttributes([.font: Text.style8.font], for: .normal)
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
}

extension PublicArchiveViewController: PublicArchiveChildDelegate {
    func childVC(_ vc: UIViewController, didScrollToOffset offset: CGPoint) -> Bool {
        if (-headerViewTopConstraint.constant >= headerContainerView.bounds.height && offset.y > 0) ||
            (headerViewTopConstraint.constant >= 0 && offset.y < 0) {
            return false
        } else {
            headerViewTopConstraint.constant -= offset.y
            if headerViewTopConstraint.constant > 0 {
                headerViewTopConstraint.constant = 0
            } else if -headerViewTopConstraint.constant > headerContainerView.bounds.height {
                headerViewTopConstraint.constant = -headerContainerView.bounds.height
            }
            
            return true
        }
    }
}

// MARK: - MyFilesViewModelPickerDelegate
extension PublicArchiveViewController: MyFilesViewModelPickerDelegate {
    func myFilesVMDidPickFile(viewModel: MyFilesViewModel, file: FileViewModel) {
        dismiss(animated: true) {
            let alert = UIAlertController(title: "Updating...".localized(), message: "Please wait while your banner is being updated".localized(), preferredStyle: .alert)
            self.present(alert, animated: true, completion: {
                if self.isPickingProfilePicture {
                    self.viewModel?.updateProfilePicture(file: file, then: { status in
                        self.dismiss(animated: true, completion: {
                            if status == .success, let thumbURL = URL(string: file.thumbnailURL2000) {
                                self.profilePhotoImageView.sd_setImage(with: thumbURL)
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
