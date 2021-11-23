//
//  ProfilePageAboutCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.11.2021.
//

import UIKit

class ProfilePageAboutCollectionViewCell: ProfilePageBaseCollectionViewCell {
    
    static let identifier = "ProfilePageAboutCollectionViewCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var contentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentLabel.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
        contentLabel.textColor = .darkGray
        contentLabel.font = Text.style12.font
    }
    
    func configure(_ aboutText: String = "") {
        contentLabel.text = aboutText.localized()
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
