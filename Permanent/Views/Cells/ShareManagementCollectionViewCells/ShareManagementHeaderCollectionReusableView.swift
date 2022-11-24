//
//  ShareManagementHeaderCollectionReusableView.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 23.11.2022.
//

import UIKit

class ShareManagementHeaderCollectionReusableView: UICollectionReusableView {
    static let identifier = "ShareManagementHeaderCollectionReusableView"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var badgeLabel: UILabel!
    
    static func nib() -> UINib {
        return UINib(nibName: identifier, bundle: nil)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        badgeLabel.backgroundColor = .paleRed
        badgeLabel.textColor = .white
        badgeLabel.font = Text.style40.font
        badgeLabel.layer.cornerRadius = 9
        badgeLabel.clipsToBounds = true
        badgeLabel.isHidden = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        badgeLabel.text = nil
        badgeLabel.isHidden = true
    }
    
    func configure(withTitle title: String, badgeValue badge: Int, isRedBadge: Bool = false) {
        let baseAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.middleGray,
            NSAttributedString.Key.font: Text.style37.font
        ]
        
        if isRedBadge {
            badgeLabel.text = "\(badge)"
            badgeLabel.isHidden = false
            
            titleLabel.attributedText = NSAttributedString(string: title, attributes: baseAttributes)
        } else {
            let badgeString = " (\(badge))"
            let attributedText = NSMutableAttributedString(string: title + badgeString, attributes: baseAttributes)
            attributedText.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.lightGray], range: (attributedText.string as NSString).range(of: badgeString))
            
            titleLabel.attributedText = attributedText
        }
    }
}
