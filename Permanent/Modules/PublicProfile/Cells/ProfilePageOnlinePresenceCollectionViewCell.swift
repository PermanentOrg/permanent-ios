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
        
        let attributedString = NSMutableAttributedString(string: "website link")
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: 1, range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.primary, range: NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(NSAttributedString.Key.font, value: TextFontStyle.style5.font, range: NSRange(location: 0, length: attributedString.length))
        
        linkLabel.attributedText = attributedString
    }
    
    func configure(link: String?) {
        linkLabel.text = link
    }

    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    static func size(collectionView: UICollectionView) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 25)
    }
}
