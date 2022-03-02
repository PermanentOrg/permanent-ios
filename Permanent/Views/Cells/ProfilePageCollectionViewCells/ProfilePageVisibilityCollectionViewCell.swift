//
//  ProfilePageVisibilityCollectionViewCell.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 01.03.2022.
//

import UIKit

class ProfilePageVisibilityCollectionViewCell: UICollectionViewCell {
    static let identifier = "ProfilePageVisibilityCollectionViewCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var isPublicSwitch: UISwitch!
    
    var switchAction: ((ProfilePageVisibilityCollectionViewCell) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        isPublicSwitch.onTintColor = .primary
        titleLabel.font = Text.style32.font
        subtitleLabel.font = Text.style30.font
        subtitleLabel.textColor = .middleGray
    }
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    @IBAction func switchValueChanged(_ sender: Any) {
        switchAction?(self)
    }
    
}
