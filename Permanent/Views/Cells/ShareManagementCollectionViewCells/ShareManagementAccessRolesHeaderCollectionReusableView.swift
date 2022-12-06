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
        
        let attributedText = NSAttributedString(string: "What's this".localized(), attributes: [.foregroundColor: UIColor.middleGray, .font: Text.style5.font])
        rightButton.setAttributedTitle(attributedText, for: .normal)
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    @IBAction func rightButtonAction(_ sender: Any) {
        rightButtonTapped?(self)
    }
}
