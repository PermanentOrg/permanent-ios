//
//  ShareManagementAccessRolesHeaderCollectionReusableView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.11.2022.
//

import UIKit

class ShareManagementAccessRolesHeaderCollectionReusableView: UICollectionReusableView {
    static let identifier = "ShareManagementAccessRolesHeaderCollectionReusableView"
    
    @IBOutlet weak var bottomSeparatorView: UIView!
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var headerTitle: UILabel!
    @IBOutlet weak var rightButton: UIButton!
    
    var rightButtonTapped: ((ShareManagementAccessRolesHeaderCollectionReusableView) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        bottomSeparatorView.backgroundColor = .galleryGray
        leftImageView.image = UIImage(named: "manageSharing")?.withRenderingMode(.alwaysTemplate)
        leftImageView.tintColor = .lightGray
        
        headerTitle.text = "Access Roles".localized()
        headerTitle.font = Text.style41.font
        headerTitle.textColor = .darkBlue
        
        rightButton.setTitle("What's this".localized(), for: .normal)
        rightButton.titleLabel?.textColor = .middleGray
        rightButton.titleLabel?.font = Text.style5.font
        rightButton.tintColor = .middleGray
    }
    
    func configure(hideContent: Bool) {
        bottomSeparatorView.isHidden = hideContent
        leftImageView.isHidden = hideContent
        headerTitle.isHidden = hideContent
        rightButton.isHidden = hideContent
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    @IBAction func rightButtonAction(_ sender: Any) {
        rightButtonTapped?(self)
    }
}
