//
//  ProfilePagePersonalPresenceCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.11.2021.
//

import UIKit

class ProfilePageOnlinePresenceCollectionViewCell: ProfilePageBaseCollectionViewCell {
  
    static let identifier = "ProfilePageOnlinePresenceCollectionViewCell"
    
    @IBOutlet weak var linkOneLabel: UILabel!
    @IBOutlet weak var linkTwoLabel: UILabel!
    @IBOutlet weak var linkThreeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let attributedString = NSMutableAttributedString.init(string: "website link")
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: 1, range: NSRange.init(location: 0, length: attributedString.length))
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.primary, range: NSRange.init(location: 0, length: attributedString.length))
        attributedString.addAttribute(NSAttributedString.Key.font, value: Text.style5.font, range: NSRange.init(location: 0, length: attributedString.length))
        
        linkOneLabel.attributedText = attributedString
        linkTwoLabel.attributedText = attributedString
        linkThreeLabel.attributedText = attributedString

        linkOneLabel.text = "https://twitter.com/"
        linkTwoLabel.text = "https://www.linkedin.com/"
        linkThreeLabel.text = "https://www.instagram.com/"
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
