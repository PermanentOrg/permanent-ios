//
//  ShareManagementAccessRolesCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.11.2022.
//

import UIKit

class ShareManagementAccessRolesCollectionViewCell: UICollectionViewCell {
    static let identifier = "ShareManagementAccessRolesCollectionViewCell"
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var view: UIView!
    var cellType: ShareManagementAccessRoleCellType?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.font = Text.style34.font
        titleLabel.textColor = .middleGray
        descriptionLabel.font = Text.style38.font
        descriptionLabel.textColor = .middleGray
        descriptionLabel.text = "none"
        selectedImageView.image = UIImage(named: "accessRoleNotSelected")?.withRenderingMode(.alwaysTemplate)
        selectedImageView.tintColor = .middleGray
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        leftImageView.image = nil
        titleLabel.text = nil
        descriptionLabel.text = nil
        descriptionLabel.isHidden = true
        view.backgroundColor = .clear
        selectedImageView.image = nil
    }
    
    func configure(cellType: ShareManagementAccessRoleCellType, isSelected: Bool = false) {
        self.cellType = cellType
        
        titleLabel.text = ShareManagementAccessRoleCellType.roleToString(cellType)?.localized()
        let imageName: String = "accessRole\(ShareManagementAccessRoleCellType.roleToString(cellType) ?? "")"
        leftImageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        leftImageView.tintColor = .darkBlue
        
        setSelected(isSelected)
    }
    
    func setSelected(_ isSelected: Bool) {
        let backgroundColor: UIColor
        
        if isSelected {
            let permissions = ShareManagementAccessRoleCellType.roleToPermissionString(cellType)
            let permissionsLocalized = permissions.flatMap({ item in
                item.joined(separator:", ").localized()
            })
            
            descriptionLabel.text = permissionsLocalized
            backgroundColor = .whiteGray
            selectedImageView.image = UIImage(named: "accessRoleSelected")?.withRenderingMode(.alwaysTemplate)
            selectedImageView.tintColor = .darkBlue
            titleLabel.textColor = .darkBlue
            titleLabel.font = Text.style35.font
            descriptionLabel.isHidden = false
        } else {
            backgroundColor = .backgroundPrimary
            selectedImageView.image = UIImage(named: "accessRoleNotSelected")?.withRenderingMode(.alwaysTemplate)
            selectedImageView.tintColor = .middleGray
            titleLabel.font = Text.style34.font
            descriptionLabel.isHidden = true
        }
        UIView.animate(withDuration: 0.2) { [self] in
            view.backgroundColor = backgroundColor
        }
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
