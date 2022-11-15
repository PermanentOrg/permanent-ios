//
//  ShareManagementToggleCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.11.2022.
//

import UIKit

class ShareManagementToggleCollectionViewCell: UICollectionViewCell {
    static let identifier = "ShareManagementToggleCollectionViewCell"
    
    @IBOutlet weak var cellTitleLabel: UILabel!
    @IBOutlet weak var cellSubtitleLabel: UILabel!
    @IBOutlet weak var activateSwitch: UISwitch!
    

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
