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

class PublicArchiveViewController: UIViewController {
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
    
    var profilePageVC: PublicProfilePageViewController!
    var archiveVC: PublicArchiveFileViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let archiveName = archiveData.fullName {
            title = "The <ARCHIVE_NAME> Archive".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: archiveName)
        }

        profilePageVC = UIViewController.create(withIdentifier: .profilePage, from: .profile) as? PublicProfilePageViewController
        profilePageVC.delegate = self
        profilePageVC.archiveData = archiveData
        addChild(profilePageVC)
        profilePageVC.view.frame = collectionViewContainer.bounds
        profilePageVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionViewContainer.addSubview(profilePageVC.view)
        profilePageVC.didMove(toParent: self)
        profilePageVC.view.isHidden = true
        
        archiveVC = UIViewController.create(withIdentifier: .publicArchiveFileBrowser, from: .profile) as? PublicArchiveFileViewController
        archiveVC.delegate = self
        archiveVC.archiveData = archiveData
        addChild(archiveVC)
        archiveVC.view.frame = collectionViewContainer.bounds
        archiveVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionViewContainer.addSubview(archiveVC.view)
        archiveVC.didMove(toParent: self)
        
        setupHeaderView()
    }
    
    func setupHeaderView() {
        profileBannerImageView.backgroundColor = .lightGray
        profilePhotoImageView.backgroundColor = .darkGray
        
        changeProfileBannerButton.setImage(UIImage(named: "cameraIcon")!, for: .normal)
        changeProfileBannerButton.tintColor = .primary

        changeProfileBannerPhotoButtonView.backgroundColor = .galleryGray
        changeProfileBannerPhotoButtonView.clipsToBounds = true
        changeProfileBannerPhotoButtonView.layer.cornerRadius = changeProfileBannerPhotoButtonView.frame.width / 2
        changeProfileBannerPhotoButtonView.layer.borderColor = UIColor.white.cgColor
        changeProfileBannerPhotoButtonView.layer.borderWidth = 1
        
        changeProfilePhotoButton.setImage(UIImage(named: "cameraIcon")!, for: .normal)
        changeProfilePhotoButton.tintColor = .primary
        
        changeProfilePhotoButtonView.backgroundColor = .galleryGray
        changeProfilePhotoButtonView.clipsToBounds = true
        changeProfilePhotoButtonView.layer.cornerRadius = changeProfilePhotoButtonView.frame.width / 2
        changeProfilePhotoButtonView.layer.borderColor = UIColor.white.cgColor
        changeProfilePhotoButtonView.layer.borderWidth = 1
        
        profilePhotoBorderView.layer.cornerRadius = 2
        profilePhotoImageView.layer.cornerRadius = 2
        profilePhotoImageView.sd_setImage(with: URL(string: archiveData.thumbURL200!))
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
