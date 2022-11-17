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
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
