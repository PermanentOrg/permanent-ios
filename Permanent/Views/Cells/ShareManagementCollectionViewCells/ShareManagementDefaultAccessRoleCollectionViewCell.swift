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
    
    var editButtonAction: ((ShareManagementDefaultAccessRoleCollectionViewCell) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        editDefaultRoleButton.setTitle("", for: .normal)
        
        titleLabel.font = Text.style34.font
        titleLabel.textColor = .darkBlue
        titleLabel.text = "Default access role".localized()
        
        detailsLabel.font = Text.style38.font
        detailsLabel.textColor = .middleGray
        detailsLabel.text = "Archives are granted access with this role by default.".localized()
        
        userDefaultRoleBackgroundView.backgroundColor = UIColor.tangerine.withAlphaComponent(0.2)
        userDefaultRoleBackgroundView.layer.cornerRadius = 4
        
        userDefaultRoleLabel.font = Text.style36.font
        userDefaultRoleLabel.textColor = UIColor.darkBlue
    }
    
    func configure(defaultRole: AccessRole = .viewer) {
        userDefaultRoleLabel.text = defaultRole.groupName.localized().uppercased()
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        editButtonAction?(self)
    }
}
