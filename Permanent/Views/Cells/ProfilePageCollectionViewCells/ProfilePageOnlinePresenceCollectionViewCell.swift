//
//  ProfilePagePersonalPresenceCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.11.2021.
//

import UIKit

class ProfilePageOnlinePresenceCollectionViewCell: ProfilePageBaseCollectionViewCell {
  
    static let identifier = "ProfilePageOnlinePresenceCollectionViewCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var linkOneLabel: UILabel!
    @IBOutlet weak var linkTwoLabel: UILabel!
    @IBOutlet weak var linkThreeLabel: UILabel!
    @IBOutlet weak var readMoreButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.text = "Online Presence".localized()
        titleLabel.textColor = .primary
        titleLabel.font = Text.style9.font
        
        editButton.setAttributedTitle(NSAttributedString(string: "Edit".localized(), attributes: [.font: Text.style17.font, .foregroundColor: UIColor.darkGray]), for: .normal)
        editButton.setAttributedTitle(NSAttributedString(string: "Edit".localized(), attributes: [.font: Text.style17.font, .foregroundColor: UIColor.lightGray]), for: .highlighted)
        
        readMoreButton.setTitle("Read More".localized(), for: .normal)
        readMoreButton.setAttributedTitle(NSAttributedString(string: "Read More".localized(), attributes: [.font: Text.style18.font, .foregroundColor: UIColor.darkGray]), for: .normal)
        readMoreButton.setAttributedTitle(NSAttributedString(string: "Read More".localized(), attributes: [.font: Text.style18.font, .foregroundColor: UIColor.lightGray]), for: .highlighted)
        
        let attributedString = NSMutableAttributedString.init(string: "website link")
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: 1, range: NSRange.init(location: 0, length: attributedString.length))
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.primary, range: NSRange.init(location: 0, length: attributedString.length))
        attributedString.addAttribute(NSAttributedString.Key.font, value: Text.style5.font, range: NSRange.init(location: 0, length: attributedString.length))
        
        linkOneLabel.attributedText = attributedString
        linkTwoLabel.attributedText = attributedString
        linkThreeLabel.attributedText = attributedString

        temporaryContent()
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    func temporaryContent() {
        
        linkOneLabel.text = "https://twitter.com/"
        linkTwoLabel.text = "https://www.linkedin.com/"
        linkThreeLabel.text = "https://www.instagram.com/"
    }
}
