//
//  ShareManagementSharedWithCollectionViewCell.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 22.11.2022.
//

import UIKit

class ShareManagementSharedWithCollectionViewCell: UICollectionViewCell {
    static let identifier = "ShareManagementSharedWithCollectionViewCell"

    @IBOutlet weak var archiveImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var roleContainerView: UIView!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    var leftButtonAction: ((ShareManagementSharedWithCollectionViewCell) -> Void)?
    var rightButtonAction: ((ShareManagementSharedWithCollectionViewCell) -> Void)?
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        nameLabel.font = Text.style34.font
        nameLabel.textColor = UIColor.middleGray
        
        roleContainerView.backgroundColor = UIColor.tangerine.withAlphaComponent(0.2)
        roleContainerView.layer.cornerRadius = 4
        
        roleLabel.font = Text.style36.font
        roleLabel.textColor = UIColor.darkBlue
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        leftButtonAction = nil
        rightButtonAction = nil
    }
    
    func configure(withShareVO shareVO: ShareVOData) {
        nameLabel.text = "The " + (shareVO.archiveVO?.fullName ?? "") + " Archive"
        roleLabel.text = AccessRole.roleForValue(shareVO.accessRole).groupName.uppercased()
        
        let url = URL(string: shareVO.archiveVO?.thumbURL200)
        archiveImageView.sd_setImage(with: url)
        
        if ArchiveVOData.Status(rawValue: shareVO.status ?? "") == .pending {
            leftButton.setImage(UIImage(named: "denyAccessIcon"), for: .normal)
            leftButton.isHidden = false
            
            rightButton.setImage(UIImage(named: "approveAccessIcon"), for: .normal)
            rightButton.isHidden = false
        } else {
            leftButton.isHidden = true
            
            rightButton.setImage(UIImage(named: "editIcon"), for: .normal)
            rightButton.isHidden = false
        }
    }
    
    @IBAction func rightButtonPressed(_ sender: Any) {
        rightButtonAction?(self)
    }
    
    @IBAction func leftButtonPressed(_ sender: Any) {
        leftButtonAction?(self)
    }
}
