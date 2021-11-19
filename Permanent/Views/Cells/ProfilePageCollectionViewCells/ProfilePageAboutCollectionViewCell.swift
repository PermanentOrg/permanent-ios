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
    @IBOutlet weak var readMoreButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.text = "About".localized()
        titleLabel.textColor = .primary
        titleLabel.font = Text.style9.font
        
        editButton.setAttributedTitle(NSAttributedString(string: "Edit".localized(), attributes: [.font: Text.style17.font, .foregroundColor: UIColor.darkGray]), for: .normal)
        editButton.setAttributedTitle(NSAttributedString(string: "Edit".localized(), attributes: [.font: Text.style17.font, .foregroundColor: UIColor.lightGray]), for: .highlighted)
        
        contentLabel.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
        contentLabel.textColor = .darkGray
        contentLabel.font = Text.style12.font
        
        readMoreButton.setTitle("Read More".localized(), for: .normal)
        readMoreButton.setAttributedTitle(NSAttributedString(string: "Read More".localized(), attributes: [.font: Text.style18.font, .foregroundColor: UIColor.darkGray]), for: .normal)
        readMoreButton.setAttributedTitle(NSAttributedString(string: "Read More".localized(), attributes: [.font: Text.style18.font, .foregroundColor: UIColor.lightGray]), for: .highlighted)
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
