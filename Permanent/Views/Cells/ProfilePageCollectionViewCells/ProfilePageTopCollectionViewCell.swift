//
//  ProfilePageTopCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 10.11.2021.
//

import UIKit

class ProfilePageTopCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "ProfilePageTopCollectionViewCell"
    
    @IBOutlet weak var profileBannerImageView: UIImageView!
    @IBOutlet weak var changeProfileBannerButton: UIButton!
    @IBOutlet weak var profilePhotoImageView: UIImageView!
    @IBOutlet weak var changeProfilePhotoButton: UIButton!
    @IBOutlet weak var changeProfileBannerPhotoButtonView: UIView!
    @IBOutlet weak var changeProfilePhotoButtonView: UIView!
    @IBOutlet weak var profilePhotoBorderView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
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
    }
    
    func configure(profileBannerImageUrl: String?, profilePhotoImageUrl: String?) {
        if let bannerPhotoUrl = profileBannerImageUrl {
            profilePhotoImageView.sd_setImage(with: URL(string: bannerPhotoUrl))
        }
        
        if let profilePhotoUrl = profilePhotoImageUrl {
            profilePhotoImageView.sd_setImage(with: URL(string: profilePhotoUrl))
        }
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
