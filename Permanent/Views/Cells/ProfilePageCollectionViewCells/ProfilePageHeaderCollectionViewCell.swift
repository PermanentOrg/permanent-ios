//
//  ProfilePageHeaderCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.11.2021.
//

import UIKit

class ProfilePageHeaderCollectionViewCell: UICollectionReusableView {

    static let identifier = "ProfilePageHeaderCollectionViewCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var buttonImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        titleLabel.textColor = .primary
        titleLabel.font = Text.style9.font
        
        configure(titleLabel: "About", buttonText: "Edit")
    }
    
    func configure(titleLabel: String = "", buttonText: String = "", buttonIsHidden: Bool = false ) {
        self.titleLabel.text = titleLabel.localized()
        
        editButton.setAttributedTitle(NSAttributedString(string: buttonText.localized(), attributes: [.font: Text.style17.font, .foregroundColor: UIColor.darkGray]), for: .normal)
        editButton.setAttributedTitle(NSAttributedString(string: buttonText.localized(), attributes: [.font: Text.style17.font, .foregroundColor: UIColor.lightGray]), for: .highlighted)
        
        editButton.isHidden  = buttonIsHidden
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }

}
