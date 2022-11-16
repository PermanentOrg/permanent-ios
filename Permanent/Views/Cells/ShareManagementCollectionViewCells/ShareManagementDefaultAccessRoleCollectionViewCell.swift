//
//  ShareManagementDefaultAccessRoleCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.11.2022
//

import UIKit

class ShareManagementDefaultAccessRoleCollectionViewCell: UICollectionViewCell {
    static let identifier = "ShareManagementDefaultAccessRoleCollectionViewCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var userDefaultRoleBackgroundView: UIView!
    @IBOutlet weak var userDefaultRoleLabel: UILabel!
    @IBOutlet weak var editDefaultRoleButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        editDefaultRoleButton.setTitle("", for: .normal)
        
        titleLabel.font = Text.style34.font
        titleLabel.textColor = .darkBlue
        
        detailsLabel.font = Text.style38.font
        detailsLabel.textColor = .middleGray
        
        userDefaultRoleBackgroundView.backgroundColor = .tangerine
        userDefaultRoleBackgroundView.layer.opacity = 0.2
        
        userDefaultRoleLabel.font = Text.style36.font
        userDefaultRoleLabel.textColor = .darkBlue
    }
    
    func configure(defaultRole: String = "Viewer") {
        titleLabel.text = "Default access role".localized()
        detailsLabel.text = "Archives are granted access with this role by default.".localized()
        userDefaultRoleLabel.text = defaultRole.localized().uppercased()
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
