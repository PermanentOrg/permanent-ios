//
//  ProfilePagePersonalPresenceCollectionViewCell.swift
//  Permanent
//
//  Created by Lucian Cerbu on 16.11.2021.
//

import UIKit

class ProfilePageOnlinePresenceCollectionViewCell: UICollectionViewCell {
  
    static let identifier = "ProfilePageOnlinePresenceCollectionViewCell"
    
    @IBOutlet weak var linkLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let attributedString = NSMutableAttributedString.init(string: "website link")
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: 1, range: NSRange.init(location: 0, length: attributedString.length))
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.primary, range: NSRange.init(location: 0, length: attributedString.length))
        attributedString.addAttribute(NSAttributedString.Key.font, value: Text.style5.font, range: NSRange.init(location: 0, length: attributedString.length))
        
        linkLabel.attributedText = attributedString

        linkLabel.text = "https://twitter.com/"
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
}
