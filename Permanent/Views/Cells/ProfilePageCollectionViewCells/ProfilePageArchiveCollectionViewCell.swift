//
//  ProfilePageArchiveCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.11.2021.
//

import UIKit

class ProfilePageArchiveCollectionViewCell: ProfilePageBaseCollectionViewCell {
    
    static let identifier = "ProfilePageArchiveCollectionViewCell"
    
    @IBOutlet weak var archiveTitleLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        archiveTitleLabel.text = "Archive".localized()
        archiveTitleLabel.textColor = .primary
        archiveTitleLabel.font = Text.style9.font

        
        shareButton.setTitle("Share".localized(), for: .normal)
        shareButton.setFont(Text.style12.font)
        shareButton.setTitleColor(.darkGray, for: .normal)
        shareButton.setTitleColor(.lightGray, for: .highlighted)
        
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
